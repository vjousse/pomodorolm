extern crate dirs;
use crate::config::{pomodoro_state_from_config, Config};
use crate::pomodoro::{self, get_session_info, SessionInfo, SessionStatus, SessionType};

use anyhow::{Context, Result};
use std::fs;
use std::path::Path;
use std::time::{Duration, SystemTime};
use tokio::time::interval;

pub fn run(config_dir_name: &str, display_label: bool) -> Result<()> {
    let config_dir = dirs::config_dir()
        .expect("Error while getting the config directory")
        .join(config_dir_name);

    let config =
        Config::get_or_create_from_disk(&config_dir, None).context("Unable to get config file")?;

    // Initialize the Tokio runtime
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(run_pomodoro_checker(config, display_label))
}

async fn run_pomodoro_checker(config: Config, display_label: bool) -> Result<()> {
    let cache_dir = dirs::cache_dir().context("Error while getting the cache directory")?;
    let mut pomodoro = pomodoro_state_from_config(&config);

    let session_file_path = cache_dir.join("pomodorolm_session");
    let mut interval = interval(Duration::from_secs(1));

    loop {
        interval.tick().await;

        if file_exists(&session_file_path) {
            let session_info = match get_session_info(&session_file_path) {
                Ok(info) => info,
                Err(e) => {
                    eprintln!(
                        "Unable to parse session line: {e}. Fallback to config defaults: {}/{}.",
                        pomodoro.config.default_focus_label, pomodoro.config.focus_duration
                    );
                    SessionInfo {
                        label: pomodoro.config.default_focus_label.clone(),
                        start_time: SystemTime::now(),
                        session_type: SessionType::Focus,
                    }
                }
            };
            pomodoro.current_session.label = Some(session_info.label.clone());
            pomodoro.current_session.session_type = session_info.session_type;

            if let Some(remaining_time) =
                get_remaining_time(&session_file_path, pomodoro.config.focus_duration as u64).await
            {
                let total_seconds = pomodoro.config.focus_duration as u64; // Total time for Pomodoro in seconds
                let remaining_seconds = remaining_time.as_secs();
                let elapsed_seconds = total_seconds - remaining_seconds;
                if elapsed_seconds == 1 {
                    // The pomodoro was just created
                    println!("-> New pomodoro created")
                }

                // Create the progress bar
                let progress_bar = create_progress_bar(total_seconds, elapsed_seconds);
                let formatted_time = format_time(remaining_seconds);

                // Check if remaining time is zero
                if remaining_seconds == 0 {
                    // Delete the session file
                    fs::remove_file(&session_file_path).context("Failed to delete session file")?;
                    println!("-> Pomodoro ended normally");
                    continue;
                }

                if display_label {
                    println!("{progress_bar} {formatted_time} {}", session_info.label);
                } else {
                    println!("{progress_bar} {formatted_time}");
                }
            }
        } else {
            if pomodoro.current_session.status == SessionStatus::Running {
                println!("-> Pomodoro stopped outside of the app");
                pomodoro = pomodoro::reset_round(&pomodoro)?;
            }
            println!("P -");
        }
    }
}

fn file_exists(path: &Path) -> bool {
    fs::metadata(path).is_ok()
}

async fn get_remaining_time(path: &Path, duration: u64) -> Option<Duration> {
    if let Ok(metadata) = fs::metadata(path) {
        if let Ok(modified_time) = metadata.modified() {
            let now = SystemTime::now();
            let elapsed = now.duration_since(modified_time).ok()?;
            let total_duration = Duration::from_secs(duration);

            if elapsed >= total_duration {
                return Some(Duration::from_secs(0)); // Return zero if the time is up
            }

            let remaining = total_duration - elapsed;
            return Some(remaining);
        }
    }
    None
}

fn create_progress_bar(total_seconds: u64, elapsed_seconds: u64) -> String {
    let total_hashes = 10; // Total number of '#' in the progress bar
    let filled_length =
        (elapsed_seconds as f64 / total_seconds as f64 * total_hashes as f64).round() as usize;
    let hashes = "#".repeat(total_hashes - filled_length);
    let dots = "·".repeat(filled_length);

    format!("P {hashes}{dots}")
}

fn format_time(seconds: u64) -> String {
    let minutes = seconds / 60;
    let remaining_seconds = seconds % 60;
    format!("{minutes:02}:{remaining_seconds:02}")
}
