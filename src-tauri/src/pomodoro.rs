use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fmt;
use std::fs;
use std::fs::File;
use std::io;
use std::path::PathBuf;
use std::str::FromStr;

#[derive(PartialEq, Copy, Debug, Serialize, Deserialize, Clone)]
pub enum SessionStatus {
    NotStarted,
    Paused,
    Running,
}

#[derive(Copy, Debug, PartialEq, Serialize, Deserialize, Clone)]
pub enum SessionType {
    Focus,
    ShortBreak,
    LongBreak,
}
#[derive(Debug, PartialEq, Eq)]
pub struct ParseSessionTypeError;

impl fmt::Display for ParseSessionTypeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "unable to parse session type")
    }
}

impl Error for ParseSessionTypeError {}

impl FromStr for SessionType {
    type Err = ParseSessionTypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let opt = match s.to_lowercase().as_str() {
            "focus" => Self::Focus,
            "longbreak" => Self::LongBreak,
            "shortbreak" => Self::ShortBreak,
            _ => return Err(ParseSessionTypeError),
        };
        Ok(opt)
    }
}

type Seconds = u16;

#[derive(PartialEq, Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub auto_start_long_break_timer: bool,
    pub auto_start_short_break_timer: bool,
    pub auto_start_focus_timer: bool,
    pub default_focus_label: String,
    pub default_long_break_label: String,
    pub default_short_break_label: String,
    pub focus_duration: Seconds,
    pub long_break_duration: Seconds,
    pub max_focus_rounds: u16,
    pub session_file: PathBuf,
    pub short_break_duration: Seconds,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            auto_start_long_break_timer: false,
            auto_start_short_break_timer: false,
            auto_start_focus_timer: false,
            default_focus_label: "Focus".to_owned(),
            default_long_break_label: "Long Break".to_owned(),
            default_short_break_label: "Short Break".to_owned(),
            focus_duration: 25 * 60,
            long_break_duration: 20 * 60,
            max_focus_rounds: 4,
            session_file: dirs::cache_dir()
                .map_or(PathBuf::from("~/.cache/pomodorolm_session"), |p| {
                    p.join("pomodorolm_session")
                }),
            short_break_duration: 5 * 60,
        }
    }
}

#[derive(PartialEq, Debug, Serialize, Deserialize, Clone)]
pub struct Pomodoro {
    pub config: Config,
    pub current_session: Session,
    // A work round is a Focus + a Break (short or long)
    pub current_work_round_number: u16,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PomodoroUnborrowed {
    pub config: Config,
    pub current_session: SessionUnburrowed,
    pub current_work_round_number: u16,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SessionUnburrowed {
    current_time: Seconds,
    label: Option<String>,
    session_type: SessionType,
    status: SessionStatus,
}

impl Default for Pomodoro {
    fn default() -> Self {
        Pomodoro {
            config: Config::default(),
            current_session: Session::default(),
            current_work_round_number: 1,
        }
    }
}

impl Pomodoro {
    pub fn duration_of_session(&self, session: &Session) -> Seconds {
        match session.session_type {
            SessionType::Focus => self.config.focus_duration,
            SessionType::LongBreak => self.config.long_break_duration,
            SessionType::ShortBreak => self.config.short_break_duration,
        }
    }

    pub fn to_unborrowed(&self) -> PomodoroUnborrowed {
        PomodoroUnborrowed {
            config: self.config.clone(),
            current_work_round_number: self.current_work_round_number,
            current_session: SessionUnburrowed {
                current_time: self.current_session.current_time,
                session_type: self.current_session.session_type,
                status: self.current_session.status,
                label: self.current_session.label.clone(),
            },
        }
    }
}

#[derive(PartialEq, Debug, Serialize, Deserialize, Clone)]
pub struct Session {
    pub current_time: Seconds,
    pub label: Option<String>,
    pub session_file: Option<PathBuf>,
    pub session_type: SessionType,
    pub status: SessionStatus,
}

impl Default for Session {
    fn default() -> Self {
        Session {
            current_time: 0,
            label: None,
            session_file: None,
            session_type: SessionType::Focus,
            status: SessionStatus::NotStarted,
        }
    }
}

pub fn pause(pomodoro: &Pomodoro) -> Pomodoro {
    Pomodoro {
        current_session: Session {
            status: SessionStatus::Paused,
            label: pomodoro.current_session.label.clone(),
            session_file: pomodoro.current_session.session_file.clone(),
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    }
}

pub fn play(pomodoro: &Pomodoro) -> io::Result<Pomodoro> {
    if pomodoro.current_session.session_file.is_none() {
        eprintln!("[rust] creating {:?}", pomodoro.config.session_file);
        fs::create_dir_all(pomodoro.config.session_file.clone().parent().unwrap())?;
        File::create(pomodoro.config.session_file.clone())?;
    }

    Ok(Pomodoro {
        current_session: Session {
            status: SessionStatus::Running,
            label: pomodoro.current_session.label.clone(),
            session_file: Some(pomodoro.config.session_file.clone()),
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    })
}

pub fn reset_round(pomodoro: &Pomodoro) -> Pomodoro {
    Pomodoro {
        current_session: Session {
            status: SessionStatus::NotStarted,
            current_time: 0,
            label: pomodoro.current_session.label.clone(),
            session_file: pomodoro.current_session.session_file.clone(),
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    }
}

pub fn reset_session(pomodoro: &Pomodoro) -> Pomodoro {
    Pomodoro {
        current_session: Session {
            status: SessionStatus::NotStarted,
            current_time: 0,
            label: pomodoro.current_session.label.clone(),
            session_type: SessionType::Focus,
        },
        current_work_round_number: 1,
        ..*pomodoro
    }
}

pub fn get_next_session(pomodoro: &Pomodoro) -> Session {
    let session = pomodoro.current_session.clone();
    match session.session_type {
        SessionType::Focus => {
            if pomodoro.current_work_round_number == pomodoro.config.max_focus_rounds {
                Session {
                    session_type: SessionType::LongBreak,
                    status: if pomodoro.config.auto_start_long_break_timer {
                        SessionStatus::Running
                    } else {
                        SessionStatus::NotStarted
                    },

                    ..Default::default()
                }
            } else {
                Session {
                    session_type: SessionType::ShortBreak,
                    status: if pomodoro.config.auto_start_short_break_timer {
                        SessionStatus::Running
                    } else {
                        SessionStatus::NotStarted
                    },
                    ..Default::default()
                }
            }
        }
        _ => Session {
            session_type: SessionType::Focus,
            status: if pomodoro.config.auto_start_focus_timer {
                SessionStatus::Running
            } else {
                SessionStatus::NotStarted
            },
            ..Session::default()
        },
    }
}

pub fn next(pomodoro: &Pomodoro) -> Pomodoro {
    Pomodoro {
        current_session: get_next_session(pomodoro),
        current_work_round_number: match pomodoro.current_session.session_type {
            SessionType::ShortBreak => pomodoro.current_work_round_number + 1,
            SessionType::LongBreak => 1,
            _ => pomodoro.current_work_round_number,
        },
        config: pomodoro.config.clone(),
    }
}

pub fn tick(pomodoro: &Pomodoro) -> Pomodoro {
    let session = pomodoro.current_session.clone();

    match session.status {
        // Tick should do something only if the current session is in running mode
        SessionStatus::Running => {
            // If it was the last tick, return the next status
            if session.current_time + 1 == pomodoro.duration_of_session(&session) {
                return next(pomodoro);
            }

            // If we're not a the end of a session, just update the time of the current session
            Pomodoro {
                current_session: Session {
                    current_time: session.current_time + 1,
                    label: session.label,
                    session_file: pomodoro.current_session.session_file.clone(),
                    ..pomodoro.current_session
                },
                config: pomodoro.config.clone(),
                ..*pomodoro
            }
        }
        _ => pomodoro.clone(),
    }
}
