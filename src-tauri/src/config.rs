use crate::pomodoro;
use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::path::{Path, PathBuf};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub always_on_top: bool,
    pub auto_quit: Option<pomodoro::SessionType>,
    pub auto_start_break_timer: bool,
    #[serde(default)]
    pub auto_start_on_app_startup: bool,
    pub auto_start_work_timer: bool,
    #[serde(default = "default_focus_label")]
    pub default_focus_label: String,
    #[serde(default = "default_long_break_label")]
    pub default_long_break_label: String,
    #[serde(default = "default_short_break_label")]
    pub default_short_break_label: String,
    pub desktop_notifications: bool,
    pub focus_audio: Option<String>,
    #[serde(alias = "pomodoro_duration")]
    pub focus_duration: u16,
    pub long_break_audio: Option<String>,
    pub long_break_duration: u16,
    pub max_round_number: u16,
    #[serde(default = "default_max_session_duration")]
    pub max_session_duration: u16,
    pub minimize_to_tray: bool,
    pub minimize_to_tray_on_close: bool,
    #[serde(default)]
    pub muted: bool,
    #[serde(default = "default_session_file")]
    pub session_file: PathBuf,
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

fn default_focus_label() -> String {
    "Focus".to_string()
}
fn default_long_break_label() -> String {
    "Long break".to_string()
}
fn default_short_break_label() -> String {
    "Short break".to_string()
}
fn default_theme() -> String {
    "pomotroid".to_string()
}
fn default_session_file() -> PathBuf {
    dirs::cache_dir().map_or(PathBuf::from("~/.cache/pomodorolm_session"), |p| {
        p.join("pomodorolm_session")
    })
}

fn default_max_session_duration() -> u16 {
    90 * 60
}

impl Config {
    pub fn get_config_file_path(config_dir: &Path, config_file_name: Option<String>) -> PathBuf {
        config_dir.join(config_file_name.unwrap_or("config.toml".to_string()))
    }

    pub fn get_or_create_from_disk(
        config_dir: &Path,
        config_file_name: Option<String>,
    ) -> Result<Self> {
        let config_file_path = Self::get_config_file_path(config_dir, config_file_name);

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
            toml::from_str(toml_str.as_str())?
        })
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            always_on_top: true,
            auto_quit: None,
            auto_start_break_timer: true,
            auto_start_on_app_startup: false,
            auto_start_work_timer: true,
            default_focus_label: default_focus_label(),
            default_long_break_label: default_long_break_label(),
            default_short_break_label: default_short_break_label(),
            desktop_notifications: true,
            focus_audio: None,
            focus_duration: 25 * 60,
            long_break_audio: None,
            long_break_duration: 20 * 60,
            max_round_number: 4u16,
            max_session_duration: default_max_session_duration(),
            minimize_to_tray: true,
            minimize_to_tray_on_close: true,
            muted: false,
            session_file: dirs::cache_dir()
                .map_or(PathBuf::from("~/.cache/pomodorolm_session"), |p| {
                    p.join("pomodorolm_session")
                }),
            short_break_audio: None,
            short_break_duration: 5 * 60,
            start_minimized: false,
            system_startup_auto_start: false,
            theme: default_theme(),
            tick_sounds_during_work: true,
            tick_sounds_during_break: true,
        }
    }
}

pub fn pomodoro_config(config: &Config) -> pomodoro::Config {
    pomodoro::Config {
        auto_start_long_break_timer: config.auto_start_break_timer,
        auto_start_short_break_timer: config.auto_start_break_timer,
        auto_start_focus_timer: config.auto_start_work_timer,
        default_focus_label: config.default_focus_label.clone(),
        default_short_break_label: config.default_short_break_label.clone(),
        default_long_break_label: config.default_long_break_label.clone(),
        focus_duration: config.focus_duration,
        long_break_duration: config.long_break_duration,
        max_focus_rounds: config.max_round_number,
        session_file: config.session_file.clone(),
        short_break_duration: config.short_break_duration,
    }
}

pub fn pomodoro_state_from_config(config: &Config) -> pomodoro::Pomodoro {
    pomodoro::Pomodoro {
        config: pomodoro_config(config),
        ..pomodoro::Pomodoro::default()
    }
}
