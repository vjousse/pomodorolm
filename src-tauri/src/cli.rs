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
            let contents: String =
                fs::read_to_string(&file_path).expect("Unable to read the session file");

            // Session file format should be
            // current label;time
            //
            // `current label` can be any type of string
            // `;` is the separator
            // `time` is by default the number of mintes of the current session. You provide an int
            // in seconds, but you need to suffix it with the letter `s`
            //
            // To start a new session with the label working and a time of 20 minutes, do the
            // following:
            //
            // echo "working;20" > ~/.cache/pomodoro_session

            let parts = contents.trim().split(";").collect::<Vec<&str>>();

            // Default values
            let mut focus_duration = config.focus_duration as u64;
            let mut focus_label = "focus";

            if parts.len() == 2 {
                focus_label = parts[0];
                // Time specified in seconds, value ending with an `s`
                if parts[1].ends_with("s") {
                    focus_duration = parts[1]
                        .replace("s", "")
                        .parse::<u16>()
                        .unwrap_or(config.focus_duration)
                        as u64;
                } else {
                    // Default time specified in minutes
                    focus_duration = parts[1]
                        .parse::<u16>()
                        .unwrap_or(config.focus_duration / 60)
                        as u64;

                    focus_duration *= 60;
                }
            }
            if let Some(remaining_time) = get_remaining_time(&file_path, focus_duration).await {
                let total_seconds = focus_duration; // Total time for Pomodoro in seconds
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

                println!("{progress_bar} {formatted_time} {focus_label}");
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
