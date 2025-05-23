use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub always_on_top: bool,
    pub auto_start_work_timer: bool,
    pub auto_start_break_timer: bool,
    pub desktop_notifications: bool,
    pub focus_audio: Option<String>,
    #[serde(alias = "pomodoro_duration")]
    pub focus_duration: u16,
    pub long_break_audio: Option<String>,
    pub long_break_duration: u16,
    pub max_round_number: u16,
    pub minimize_to_tray: bool,
    pub minimize_to_tray_on_close: bool,
    #[serde(default)]
    pub muted: bool,
    pub short_break_audio: Option<String>,
    pub short_break_duration: u16,
    #[serde(default)]
    pub start_minimized: bool,
    #[serde(default)]
    pub system_startup_auto_start: bool,
    #[serde(default = "default_theme")]
    pub theme: String,
    pub tick_sounds_during_work: bool,
    pub tick_sounds_during_break: bool,
}

fn default_theme() -> String {
    "pomotroid".to_string()
}

impl Config {
    pub fn get_or_create_from_disk(
        config_dir: &PathBuf,
        config_file_name: Option<String>,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let file_name = config_file_name.unwrap_or("config.toml".to_string());
        let config_file_path = config_dir.join(file_name);

        // Create the config dir and the themes one if they don’t exist
        let _ = fs::create_dir_all(config_dir.join("themes/"));

        let metadata = fs::metadata(&config_file_path);

        Ok(if metadata.is_err() {
            let mut file = OpenOptions::new()
                .read(true)
                .write(true)
                .create(true)
                .truncate(true)
                .open(config_file_path)?;

            let default_config = Config {
                ..Default::default()
            };

            file.write_all(toml::to_string(&default_config)?.as_bytes())?;
            default_config
        } else {
            // Open the file
            let toml_str = fs::read_to_string(config_file_path)?;
            let config: Config = toml::from_str(toml_str.as_str())?;

            config
        })
    }
}
