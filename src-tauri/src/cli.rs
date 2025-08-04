extern crate dirs;
use crate::config::Config;

use std::fs;
use std::path::Path;
use std::time::{Duration, SystemTime};
use tokio::time::interval;

pub fn run(config_dir_name: &str) {
    let config_dir = dirs::config_dir()
        .expect("Error while getting the config directory")
        .join(config_dir_name);

    let config =
        Config::get_or_create_from_disk(&config_dir, None).expect("Unable to get config file");

    // Initialize the Tokio runtime
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(run_pomodoro_checker(config));
}

async fn run_pomodoro_checker(config: Config) {
    let cache_dir = dirs::cache_dir().expect("Error while getting the cache directory");

    let file_path = cache_dir.join("pomodoro_session");
    let mut interval = interval(Duration::from_secs(1));

    loop {
        interval.tick().await;

        if file_exists(&file_path).await {
            if let Some(remaining_time) =
                get_remaining_time(&file_path, config.focus_duration as u64).await
            {
                let total_seconds = config.focus_duration as u64; // Total time for Pomodoro in seconds
                let remaining_seconds = remaining_time.as_secs();
                let elapsed_seconds = total_seconds - remaining_seconds;

                // Create the progress bar
                let progress_bar = create_progress_bar(total_seconds, elapsed_seconds);
                let formatted_time = format_time(remaining_seconds);

                // Check if remaining time is zero
                if remaining_seconds == 0 {
                    // Delete the session file
                    if let Err(e) = fs::remove_file(&file_path) {
                        eprintln!("Failed to delete session file: {e}");
                    }
                    continue;
                }

                println!("{progress_bar} {formatted_time}");
            }
        } else {
            println!("P -");
        }
    }
}

async fn file_exists(path: &Path) -> bool {
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
