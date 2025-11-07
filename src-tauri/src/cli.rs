extern crate dirs;
use crate::config::{Config, pomodoro_state_from_config};
use crate::pomodoro::{self, Pomodoro, Session, SessionStatus, get_session_info_with_default};

use anyhow::{Context, Result};
use std::fs;
use std::path::{Path, PathBuf};
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

fn get_next_pomodoro_from_session_file(
    session_file_path: &PathBuf,
    previous_pomodoro: &Pomodoro,
) -> Result<Pomodoro> {
    if file_exists(session_file_path) {
        let session_info = get_session_info_with_default(session_file_path, previous_pomodoro);

        let remaining_time = get_remaining_time(
            session_file_path,
            previous_pomodoro.config.focus_duration as u64,
        )?;

        let total_seconds = previous_pomodoro.config.focus_duration as u64; // Total time for Pomodoro in seconds
        let remaining_seconds = remaining_time.as_secs();
        let elapsed_seconds = total_seconds - remaining_seconds;

        let next_pomodoro = Pomodoro {
            current_session: Session {
                label: Some(session_info.label.clone()),
                session_type: session_info.session_type,
                session_file: Some(session_file_path.to_path_buf()),
                current_time: elapsed_seconds as u16,
                status: if remaining_seconds == 0 {
                    SessionStatus::NotStarted
                } else {
                    previous_pomodoro.current_session.status
                },
                ..previous_pomodoro.current_session
            },
            config: previous_pomodoro.config.clone(),
            ..*previous_pomodoro
        };
        if previous_pomodoro.current_session.status == SessionStatus::NotStarted
            && elapsed_seconds > 0
        {
            pomodoro::play_with_session_file(&next_pomodoro, None)
        } else {
            Ok(next_pomodoro)
        }
    } else {
        // Whatever the current status, if there is no session file, we should reset the pomodoro
        // to a not started state
        pomodoro::reset_round(previous_pomodoro)
    }
}

async fn run_pomodoro_checker(config: Config, display_label: bool) -> Result<()> {
    let cache_dir = dirs::cache_dir().context("Error while getting the cache directory")?;
    let mut pomodoro = pomodoro_state_from_config(&config);

    let session_file_path = cache_dir.join("pomodorolm_session");
    let mut interval = interval(Duration::from_secs(1));

    loop {
        interval.tick().await;

        let next_pomodoro = get_next_pomodoro_from_session_file(&session_file_path, &pomodoro)?;

        if next_pomodoro.current_session.current_time == 1 {
            println!("-> New pomodoro created");
        }

        // Create the progress bar
        let progress_bar = create_progress_bar(
            next_pomodoro.config.focus_duration.into(),
            next_pomodoro.current_session.current_time.into(),
        );
        let remaining_seconds = (next_pomodoro.config.focus_duration
            - next_pomodoro.current_session.current_time) as u64;

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
        if remaining_seconds == 0 && file_exists(&session_file_path) {
            // Delete the session file
            fs::remove_file(&session_file_path).context("Failed to delete session file")?;
            println!("-> Pomodoro ended normally");
            continue;
        }

        pomodoro = next_pomodoro;

        //
        // if file_exists(&session_file_path) {
        //     let session_info = match get_session_info(&session_file_path) {
        //         Ok(info) => info,
        //         Err(e) => {
        //             eprintln!(
        //                 "Unable to parse session line: {e}. Fallback to config defaults: {}/{}.",
        //                 pomodoro.config.default_focus_label, pomodoro.config.focus_duration
        //             );
        //             SessionInfo {
        //                 label: pomodoro.config.default_focus_label.clone(),
        //                 start_time: SystemTime::now(),
        //                 session_type: SessionType::Focus,
        //             }
        //         }
        //     };
        //     pomodoro.current_session.label = Some(session_info.label.clone());
        //     pomodoro.current_session.session_type = session_info.session_type;
        //
        //     let remaining_time =
        //         get_remaining_time(&session_file_path, pomodoro.config.focus_duration as u64)?;
        //
        //     let total_seconds = pomodoro.config.focus_duration as u64; // Total time for Pomodoro in seconds
        //     let remaining_seconds = remaining_time.as_secs();
        //     let elapsed_seconds = total_seconds - remaining_seconds;
        //
        //     // Create the progress bar
        //     let progress_bar = create_progress_bar(total_seconds, elapsed_seconds);
        //     let formatted_time = format_time(remaining_seconds);
        //
        //     // Check if remaining time is zero
        //     if remaining_seconds == 0 {
        //         // Delete the session file
        //         fs::remove_file(&session_file_path).context("Failed to delete session file")?;
        //         println!("-> Pomodoro ended normally");
        //         continue;
        //     }
        //
        //     if display_label {
        //         println!("{progress_bar} {formatted_time} {}", session_info.label);
        //     } else {
        //         println!("{progress_bar} {formatted_time}");
        //     }
        // } else {
        //     if pomodoro.current_session.status == SessionStatus::Running {
        //         println!("-> Pomodoro stopped outside of the app");
        //         pomodoro = pomodoro::reset(&pomodoro)?;
        //     }
        //     println!("P -");
        // }
    }
}

fn file_exists(path: &Path) -> bool {
    fs::metadata(path).is_ok()
}

fn get_remaining_time(path: &Path, duration: u64) -> Result<Duration> {
    let modified_time = fs::metadata(path)?.modified()?;

    let now = SystemTime::now();
    let elapsed = now.duration_since(modified_time)?;
    let total_duration = Duration::from_secs(duration);

    if elapsed >= total_duration {
        return Ok(Duration::from_secs(0)); // Return zero if the time is up
    }
    let remaining = total_duration - elapsed;

    Ok(remaining)
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
