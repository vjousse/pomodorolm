extern crate dirs;
use crate::config::{Config, pomodoro_state_from_config};
use crate::pomodoro::{SessionStatus, get_next_pomodoro_from_session_file};

use anyhow::{Context, Result};
use std::fs;
use std::path::Path;
use std::time::Duration;
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
    let mut pomodoro = pomodoro_state_from_config(&config);

    let mut interval = interval(Duration::from_secs(1));

    loop {
        interval.tick().await;

        let next_pomodoro =
            get_next_pomodoro_from_session_file(&pomodoro.config.session_file, &pomodoro)?;

        if next_pomodoro.current_session.elapsed_seconds == 1 {
            println!("-> New pomodoro created");
        }

        // Create the progress bar
        let progress_bar = create_progress_bar(
            next_pomodoro.config.focus_duration.into(),
            next_pomodoro.current_session.elapsed_seconds.into(),
        );
        let remaining_seconds = (next_pomodoro.config.focus_duration
            - next_pomodoro.current_session.elapsed_seconds) as u64;

        let formatted_time = format_time(remaining_seconds);

        if next_pomodoro.current_session.status != SessionStatus::NotStarted {
            if let Some(ref label) = next_pomodoro.current_session.label
                && display_label
            {
                println!("{progress_bar} {formatted_time} {}", label);
            } else {
                println!("{progress_bar} {formatted_time}");
            }
        } else {
            if pomodoro.current_session.status == SessionStatus::Running {
                println!("-> Pomodoro stopped outside of the app");
                pomodoro = pomodoro::reset_round(&pomodoro)?;
            }
            println!("P -");
        }

        // Check if remaining time is zero
        if remaining_seconds == 0 && file_exists(&pomodoro.config.session_file) {
            // Delete the session file
            fs::remove_file(&pomodoro.config.session_file)
                .context("Failed to delete session file")?;
            println!("-> Pomodoro ended normally");
            continue;
        }

        pomodoro = next_pomodoro;
    }
}

fn file_exists(path: &Path) -> bool {
    fs::metadata(path).is_ok()
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
