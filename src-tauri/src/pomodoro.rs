use anyhow::{anyhow, Context, Result};
use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fmt;
use std::fs;
use std::fs::File;
use std::io;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::time::SystemTime;

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

impl fmt::Display for SessionType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match *self {
            SessionType::Focus => write!(f, "focus"),
            SessionType::ShortBreak => write!(f, "shortbreak"),
            SessionType::LongBreak => write!(f, "longbreak"),
        }
    }
}

#[derive(Debug)]
pub struct SessionInfo {
    pub label: String,
    pub session_type: SessionType,
    pub start_time: SystemTime,
}

#[derive(Debug)]
struct SessionLineContent {
    label: String,
    session_type: SessionType,
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
    pub start_time: Option<SystemTime>,
    pub status: SessionStatus,
}

impl Default for Session {
    fn default() -> Self {
        Session {
            current_time: 0,
            label: None,
            session_file: None,
            session_type: SessionType::Focus,
            start_time: None,
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

pub fn play(pomodoro: &Pomodoro, session_info: Option<SessionInfo>) -> Result<Pomodoro> {
    // eprintln!("[rust] playing pomodoro {pomodoro:?}");

    if pomodoro.current_session.session_file.is_none() {
        eprintln!("[rust] creating session file");
        create_session_file(pomodoro)?;
    }

    let current_session_info =
        session_info.unwrap_or(get_session_info(&pomodoro.config.session_file)?);

    let new_pomodoro = Pomodoro {
        current_session: Session {
            status: SessionStatus::Running,
            label: pomodoro.current_session.label.clone(),
            session_file: Some(pomodoro.config.session_file.clone()),
            start_time: Some(current_session_info.start_time),
            current_time: if pomodoro.current_session.start_time
                < Some(current_session_info.start_time)
            {
                0
            } else {
                pomodoro.current_session.current_time
            },
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    };
    eprintln!("[rust] new pomodoro after play {new_pomodoro:?}");
    Ok(new_pomodoro)
}

pub fn remove_session_file(pomodoro: &Pomodoro) -> io::Result<()> {
    if let Some(session_file) = &pomodoro.current_session.session_file {
        eprintln!("[rust] removing {session_file:?}");
        fs::remove_file(session_file)?;
    };
    Ok(())
}

pub fn create_session_file(pomodoro: &Pomodoro) -> io::Result<PathBuf> {
    eprintln!("[rust] creating {:?}", pomodoro.config.session_file);
    fs::create_dir_all(pomodoro.config.session_file.clone().parent().unwrap())?;
    File::create(pomodoro.config.session_file.clone())?;
    fs::write(
        &pomodoro.config.session_file,
        format!(
            "{};{}",
            pomodoro.current_session.session_type,
            pomodoro
                .current_session
                .label
                .clone()
                .unwrap_or("working".to_string())
        ),
    )?;

    Ok(pomodoro.config.session_file.clone())
}

pub fn reset_round(pomodoro: &Pomodoro) -> Result<Pomodoro> {
    remove_session_file(pomodoro)?;

    Ok(Pomodoro {
        current_session: Session {
            status: SessionStatus::NotStarted,
            current_time: 0,
            label: pomodoro.current_session.label.clone(),
            session_file: None,
            start_time: None,
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    })
}

pub fn reset_session(pomodoro: &Pomodoro) -> io::Result<Pomodoro> {
    if let Some(session_file) = &pomodoro.current_session.session_file {
        eprintln!("[rust] removing {session_file:?}");
        fs::remove_file(session_file)?;
    };

    Ok(Pomodoro {
        current_session: Session {
            status: SessionStatus::NotStarted,
            current_time: 0,
            label: pomodoro.current_session.label.clone(),
            session_file: pomodoro.current_session.session_file.clone(),
            session_type: SessionType::Focus,
            start_time: None,
        },
        config: pomodoro.config.clone(),
        current_work_round_number: 1,
    })
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

pub fn tick_with_file_session_info(
    pomodoro: &Pomodoro,
    session_info: Option<SessionInfo>,
) -> Result<Pomodoro> {
    let current_session = pomodoro.current_session.clone();

    match (session_info, current_session.start_time) {
        (Some(info), Some(current_session_start_time)) => {
            // @TODO: Here we need to check the consistency between the session_info that we have (coming from
            //  reading the session file on disk) and the state of the current pomodoro
            //  We need a way to check that the file has possibly been reset, deleted to adapt the next
            //  pomodoro state

            // If there is no session file let’s play the pomodoro, it means a new file has been
            // created
            if current_session.session_file.is_none()
                || info.start_time > current_session_start_time
            {
                play(pomodoro, Some(info))
            } else {
                Ok(pomodoro.clone())
            }
        }

        (Some(info), None) => play(pomodoro, Some(info)),
        _ => reset_round(pomodoro),
    }
}

pub fn tick(pomodoro: &Pomodoro) -> Result<Pomodoro> {
    let current_session = pomodoro.current_session.clone();

    let new_pomodoro_session_info = tick_with_file_session_info(
        pomodoro,
        get_session_info(&pomodoro.config.session_file).ok(),
    );

    if file_exists(pomodoro.config.session_file.as_path()) && current_session.session_file.is_none()
    {
        eprintln!("# -> [tick] Playing {pomodoro:?}");
        // File created externally, start the pomodoro
        play(pomodoro, None)
    } else {
        let mut new_pomodoro = match current_session.status {
            // Tick should do something if the current session is in running mode
            SessionStatus::Running => {
                // If it was the last tick, return the next status
                if current_session.current_time + 1
                    == pomodoro.duration_of_session(&current_session)
                {
                    return Ok(next(pomodoro));
                }

                // If we're not a the end of a session, just update the time of the current session
                Pomodoro {
                    current_session: Session {
                        current_time: current_session.current_time + 1,
                        label: current_session.label,
                        session_file: pomodoro.current_session.session_file.clone(),
                        ..pomodoro.current_session
                    },
                    config: pomodoro.config.clone(),
                    ..*pomodoro
                }
            }
            _ => pomodoro.clone(),
        };

        if new_pomodoro.current_session.status == SessionStatus::NotStarted {
            eprintln!("# -> [tick] Let’s remove the session file");
            remove_session_file(&new_pomodoro)?;
            new_pomodoro.current_session.session_file = None;
        }

        eprintln!("# -> [tick] Returning new_pomodoro {new_pomodoro:?}");
        Ok(new_pomodoro)
    }
}

// Session file format should be
// current session_type;label
//
// `session_type` can be any of "focus", "shortbreak", "longbreak"
// `;` is the separator
// `label` can be any type of string
//
// To start a new session with the label working and a time of 20 minutes, do the
// following:
//
// echo "focus;working" > ~/.cache/pomodorolm_session

pub fn get_session_info(session_file_path: &PathBuf) -> Result<SessionInfo> {
    if file_exists(session_file_path) {
        let line: String =
            fs::read_to_string(session_file_path).context("Unable to read the session file")?;

        let session_line_content = parse_line(line)?;

        let modified = fs::metadata(session_file_path)?.modified()?;

        Ok(SessionInfo {
            label: session_line_content.label,
            start_time: modified,
            session_type: session_line_content.session_type,
        })
    } else {
        Err(anyhow!(
            "Unable to read session file {session_file_path:?}, file doesn’t exist"
        ))
    }
}

fn file_exists(path: &Path) -> bool {
    fs::metadata(path).is_ok()
}

fn parse_line(line: String) -> Result<SessionLineContent> {
    let parts = line.trim().split(";").collect::<Vec<&str>>();

    if parts.len() != 2 {
        return Err(anyhow!(
            "Unable to read session line, it should have only 2 parts between a ;"
        ));
    }

    let session_type_string = parts[0];
    let label = parts[1];

    Ok(SessionLineContent {
        label: label.to_owned(),
        session_type: SessionType::from_str(session_type_string).context(format!(
            "Unable to read session line, unknown session type: {session_type_string}"
        ))?,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parsing_error() {
        let result = parse_line("invalid line".to_owned());
        let error = result.unwrap_err();
        assert_eq!(
            format!("{error}"),
            "Unable to read session line, it should have only 2 parts between a ;"
        );

        let result = parse_line("focus-;label".to_owned());
        let error = result.unwrap_err();
        assert_eq!(
            format!("{error}"),
            "Unable to read session line, unknown session type: focus-"
        );
    }

    #[test]
    fn parsing_ok_in_minutes() {
        let result = parse_line("Focus;label".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::Focus);

        let result = parse_line("ShortBreak;label".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::ShortBreak);

        let result = parse_line("LongBreak;label".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::LongBreak);
    }
}
