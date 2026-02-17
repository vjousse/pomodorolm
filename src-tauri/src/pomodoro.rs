use anyhow::{Context, Result, anyhow};
use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fmt;
use std::fs;
use std::fs::File;
use std::io;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::time::{Duration, SystemTime};

#[derive(PartialEq, Copy, Debug, Serialize, Deserialize, Clone)]
pub enum SessionStatus {
    NotStarted,
    Paused,
    Running,
}

#[derive(Debug, PartialEq, Eq)]
pub struct ParseSessionStatusError;

impl fmt::Display for ParseSessionStatusError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "unable to parse session status")
    }
}

impl Error for ParseSessionStatusError {}

impl FromStr for SessionStatus {
    type Err = ParseSessionStatusError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let opt = match s.to_lowercase().as_str() {
            "notstarted" => Self::NotStarted,
            "paused" => Self::Paused,
            "running" => Self::Running,
            _ => return Err(ParseSessionStatusError),
        };
        Ok(opt)
    }
}

impl fmt::Display for SessionStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match *self {
            SessionStatus::NotStarted => write!(f, "notstarted"),
            SessionStatus::Paused => write!(f, "paused"),
            SessionStatus::Running => write!(f, "running"),
        }
    }
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

#[derive(Debug, Clone)]
pub struct SessionInfo {
    pub elapsed_seconds: Seconds,
    pub label: String,
    pub session_status: SessionStatus,
    pub session_type: SessionType,
}

#[derive(Debug)]
struct SessionLineContent {
    elapsed_seconds: Option<Seconds>,
    label: String,
    session_status: SessionStatus,
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
            session_file: default_session_file(),
            short_break_duration: 5 * 60,
        }
    }
}

pub fn default_session_file() -> PathBuf {
    dirs::cache_dir().map_or(PathBuf::from("~/.cache/pomodorolm_session"), |p| {
        p.join("pomodorolm_session")
    })
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
                current_time: self.current_session.elapsed_seconds,
                session_type: self.current_session.session_type,
                status: self.current_session.status,
                label: self.current_session.label.clone(),
            },
        }
    }
}

#[derive(PartialEq, Debug, Serialize, Deserialize, Clone)]
pub struct Session {
    pub elapsed_seconds: Seconds,
    pub label: Option<String>,
    pub session_file: Option<PathBuf>,
    pub session_type: SessionType,
    pub status: SessionStatus,
}

impl fmt::Display for Session {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "{};{};{};{}",
            self.session_type,
            self.label.clone().unwrap_or("working".into()),
            self.status,
            self.elapsed_seconds
        )
    }
}

impl Default for Session {
    fn default() -> Self {
        Session {
            elapsed_seconds: 0,
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

pub fn pause_with_session_file(
    pomodoro: &Pomodoro,
    _session_info: Option<SessionInfo>,
) -> Result<Pomodoro> {
    let new_pomodoro = Pomodoro {
        current_session: Session {
            status: SessionStatus::Paused,
            label: pomodoro.current_session.label.clone(),
            session_file: pomodoro.current_session.session_file.clone(),
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    };

    write_session_file_from_pomodoro(
        &new_pomodoro,
        new_pomodoro.current_session.session_type,
        SessionStatus::Paused,
    )?;

    Ok(new_pomodoro)
}

pub fn play_with_session_file(
    pomodoro: &Pomodoro,
    session_info: Option<SessionInfo>,
) -> Result<Pomodoro> {
    eprintln!("### -> session_info: {session_info:?}");

    let mut new_pomodoro = pomodoro.clone();

    if let Some(info) = session_info {
        let current_session = Session {
            elapsed_seconds: info.elapsed_seconds,
            label: Some(info.label),
            session_file: Some(pomodoro.config.session_file.clone()),
            session_type: SessionType::Focus,
            status: SessionStatus::NotStarted,
        };

        new_pomodoro.current_session = current_session;
    }

    if pomodoro.current_session.session_file.is_none() {
        eprintln!("[rust] creating session file");
        write_session_file_from_pomodoro(
            pomodoro,
            pomodoro.current_session.session_type,
            SessionStatus::Running,
        )?;
    };

    new_pomodoro = play(&new_pomodoro)?;

    new_pomodoro.current_session.session_file = Some(pomodoro.config.session_file.clone());
    // new_pomodoro.current_session.elapsed_seconds = session_info.elapsed_seconds;

    Ok(new_pomodoro)
}

pub fn play(pomodoro: &Pomodoro) -> Result<Pomodoro> {
    let new_pomodoro = Pomodoro {
        current_session: Session {
            status: SessionStatus::Running,
            label: pomodoro.current_session.label.clone(),
            session_file: Some(pomodoro.config.session_file.clone()),
            elapsed_seconds: pomodoro.current_session.elapsed_seconds,
            ..pomodoro.current_session
        },
        config: pomodoro.config.clone(),
        ..*pomodoro
    };
    Ok(new_pomodoro)
}

pub fn remove_session_file(pomodoro: &Pomodoro) -> io::Result<()> {
    if let Some(session_file) = &pomodoro.current_session.session_file {
        // Check that the file exists
        if fs::metadata(session_file).is_ok() {
            eprintln!("[rust] removing {session_file:?}");
            fs::remove_file(session_file)?;
        };
    };
    Ok(())
}

pub fn write_session_file_from_pomodoro(
    pomodoro: &Pomodoro,
    session_type: SessionType,
    session_status: SessionStatus,
) -> io::Result<PathBuf> {
    write_session_file(
        &Session {
            status: session_status,
            label: pomodoro.current_session.label.clone(),
            session_file: Some(pomodoro.config.session_file.clone()),
            session_type,
            elapsed_seconds: pomodoro.current_session.elapsed_seconds,
        },
        pomodoro.config.session_file.clone(),
    )
}

pub fn write_session_file(session: &Session, session_file: PathBuf) -> io::Result<PathBuf> {
    eprintln!("[rust] creating {:?}", session_file);
    fs::create_dir_all(session_file.clone().parent().unwrap())?;
    File::create(session_file.clone())?;
    fs::write(&session_file, format!("{}", session))?;

    Ok(session_file.clone())
}

pub fn reset_round(pomodoro: &Pomodoro) -> Result<Pomodoro> {
    remove_session_file(pomodoro)?;

    Ok(Pomodoro {
        current_session: Session {
            status: SessionStatus::NotStarted,
            elapsed_seconds: 0,
            label: pomodoro.current_session.label.clone(),
            session_file: None,
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
            elapsed_seconds: 0,
            label: pomodoro.current_session.label.clone(),
            session_file: pomodoro.current_session.session_file.clone(),
            session_type: SessionType::Focus,
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
                    session_file: session.session_file,
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
                    session_file: session.session_file,
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
            session_file: session.session_file,
            status: if pomodoro.config.auto_start_focus_timer {
                SessionStatus::Running
            } else {
                SessionStatus::NotStarted
            },
            ..Session::default()
        },
    }
}

pub fn get_next_pomodoro(pomodoro: &Pomodoro) -> Pomodoro {
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
    let mut new_pomodoro = pomodoro.clone();

    match session_info {
        // We have some session info from the disk
        Some(info) => {
            // @TODO: Here we need to check the consistency between the session_info that we have (coming from
            //  reading the session file on disk) and the state of the current pomodoro
            //  We need a way to check that the file has possibly been reset, deleted to adapt the next
            //  pomodoro state

            // If there is no session file let’s play the pomodoro, it means a new file has been
            // created
            if new_pomodoro.current_session.session_file.is_none() {
                let new_pomodoro = play_with_session_file(pomodoro, Some(info.clone()))?;

                // // If the external file creation time is newer than the current start time, we should
                // // reset the current pomodoro
                // // @TODO: it looks like this logic should be handle elsewhere?
                // if current_session_start_time < info.start_time {
                //     new_pomodoro.current_session.elapsed_seconds = 0;
                // };
                Ok(new_pomodoro)
            } else {
                new_pomodoro.current_session.status = info.session_status;
                new_pomodoro.current_session.session_type = info.session_type;
                new_pomodoro.current_session.status = info.session_status;
                new_pomodoro.current_session.elapsed_seconds = info.elapsed_seconds;
                new_pomodoro.current_session.label = Some(info.label.clone());

                let next_pomodoro = match new_pomodoro.current_session.status {
                    // Tick should do something if the current session is in running mode
                    SessionStatus::Running => {
                        // If it was the last tick, return the next status
                        if is_end_of_session(&new_pomodoro) {
                            get_next_pomodoro(&new_pomodoro)
                        } else {
                            // If we're not a the end of a session, just update the time of the current session
                            Pomodoro {
                                // The source of truth is always the file on the disk
                                current_session: Session {
                                    elapsed_seconds: new_pomodoro.current_session.elapsed_seconds
                                        + 1,
                                    label: Some(info.label),
                                    session_file: new_pomodoro.current_session.session_file.clone(),
                                    session_type: new_pomodoro.current_session.session_type,
                                    status: new_pomodoro.current_session.status,
                                },
                                config: new_pomodoro.config.clone(),
                                ..*pomodoro
                            }
                        }
                    }
                    // If it’s not running we don’t do anything at tick
                    _ => {
                        Pomodoro {
                            // The source of truth is always the file on the disk
                            current_session: new_pomodoro.current_session,
                            config: pomodoro.config.clone(),
                            ..*pomodoro
                        }
                    }
                };

                Ok(next_pomodoro)
            }
        }
        // File is not present on disk, it may have been deleted
        // so we should reset the current round
        None => reset_round(pomodoro),
    }
}

pub fn is_end_of_session(pomodoro: &Pomodoro) -> bool {
    pomodoro.current_session.elapsed_seconds + 1
        >= pomodoro.duration_of_session(&pomodoro.current_session)
}

pub fn tick(pomodoro: &Pomodoro) -> Result<Pomodoro> {
    let current_session = pomodoro.current_session.clone();

    if file_exists(pomodoro.config.session_file.as_path()) && current_session.session_file.is_none()
    {
        // File created externally, start the pomodoro
        play_with_session_file(pomodoro, None)
    } else {
        let mut new_pomodoro = match current_session.status {
            // Tick should do something if the current session is in running mode
            SessionStatus::Running => {
                // If it was the last tick, return the next status
                if is_end_of_session(pomodoro) {
                    get_next_pomodoro(pomodoro)
                } else {
                    // If we're not a the end of a session, just update the time of the current session
                    Pomodoro {
                        current_session: Session {
                            elapsed_seconds: current_session.elapsed_seconds + 1,
                            label: current_session.label,
                            session_file: pomodoro.current_session.session_file.clone(),
                            ..pomodoro.current_session
                        },
                        config: pomodoro.config.clone(),
                        ..*pomodoro
                    }
                }
            }
            _ => pomodoro.clone(),
        };

        if new_pomodoro.current_session.status == SessionStatus::NotStarted {
            remove_session_file(&new_pomodoro)?;
            new_pomodoro.current_session.session_file = None;
        }

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

pub fn get_session_info(session_file_path: &PathBuf) -> Option<SessionInfo> {
    if file_exists(session_file_path) {
        let line: String = fs::read_to_string(session_file_path)
            .context("Unable to read the session file")
            .ok()?;

        let session_line_content = parse_line(line).ok()?;

        Some(SessionInfo {
            elapsed_seconds: session_line_content.elapsed_seconds.unwrap_or(0),
            label: session_line_content.label,
            session_status: session_line_content.session_status,
            session_type: session_line_content.session_type,
        })
    } else {
        Err(anyhow!(
            "Unable to read session file {session_file_path:?}, file doesn’t exist"
        ))
        .ok()
    }
}

pub fn get_session_info_with_default(
    session_file_path: &PathBuf,
    pomodoro: &Pomodoro,
) -> SessionInfo {
    let default = SessionInfo {
        elapsed_seconds: 0,
        label: pomodoro.config.default_focus_label.clone(),
        session_status: SessionStatus::Running,
        session_type: SessionType::Focus,
    };

    if file_exists(session_file_path) {
        let line: String = fs::read_to_string(session_file_path)
            .context("Unable to read the session file")
            .unwrap();

        let _modified = fs::metadata(session_file_path).unwrap().modified().unwrap();

        let session_line_content = parse_line(line);

        // eprintln!("session line content: {:?}", session_line_content);

        match session_line_content {
            Ok(line_content) => {
                let elapsed_seconds = match line_content.elapsed_seconds {
                    Some(seconds) => seconds,
                    None => {
                        let remaining_seconds = get_remaining_time(
                            session_file_path,
                            pomodoro.config.focus_duration as u64,
                        )
                        .unwrap_or(Duration::from_secs(pomodoro.config.focus_duration.into()))
                        .as_secs() as u16;

                        eprintln!("# -> remaining seconds: {remaining_seconds:?}");

                        let to_return = if line_content.session_status == SessionStatus::Running {
                            // @FIXME:
                            pomodoro.config.focus_duration - remaining_seconds
                        } else {
                            pomodoro.current_session.elapsed_seconds
                        };

                        eprintln!("# -> remaining seconds to return: {to_return:?}");
                        to_return
                    }
                };

                // eprintln!("# -> elapsed seconds: {elapsed_seconds:?}");

                SessionInfo {
                    elapsed_seconds,
                    label: line_content.label,
                    session_status: line_content.session_status,
                    session_type: line_content.session_type,
                }
            }
            Err(e) => {
                eprintln!(
                    "Unable to parse session line: {e}. Fallback to config defaults: {}/{}.",
                    pomodoro.config.default_focus_label, pomodoro.config.focus_duration
                );
                default
            }
        }
    } else {
        default
    }
}

fn file_exists(path: &Path) -> bool {
    fs::metadata(path).is_ok()
}

fn parse_line(line: String) -> Result<SessionLineContent> {
    let parts = line.trim().split(";").collect::<Vec<&str>>();

    if parts.len() < 2 {
        return Err(anyhow!(
            "Unable to read session line, it should have at least 2 parts between a ;"
        ));
    }

    let session_type_string = parts[0];
    let label = parts[1];

    let session_status_string = if parts.len() >= 3 {
        parts[2]
    } else {
        "running"
    };

    let elapsed_seconds = if parts.len() >= 4 {
        Some(
            parts[3]
                .parse::<Seconds>()
                .context("Unable to read timestamp in session line")?,
        )
    } else {
        None
    };

    Ok(SessionLineContent {
        elapsed_seconds,
        label: label.to_owned(),
        session_status: SessionStatus::from_str(session_status_string).context(format!(
            "Unable to read session line, unknown session status: {session_status_string}"
        ))?,
        session_type: SessionType::from_str(session_type_string).context(format!(
            "Unable to read session line, unknown session type: {session_type_string}"
        ))?,
    })
}

fn get_remaining_time(path: &Path, duration: u64) -> Result<Duration> {
    let modified_time = fs::metadata(path)?.modified()?;

    let now = SystemTime::now();
    let elapsed = now.duration_since(modified_time)?;
    let total_duration = Duration::from_secs(duration);

    if elapsed >= total_duration {
        eprintln!("# Remaining returning {:?}", Duration::from_secs(0));
        return Ok(Duration::from_secs(0)); // Return zero if the time is up
    }
    let remaining = total_duration - elapsed;

    eprintln!("# Remaining: {remaining:?}");
    Ok(remaining)
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
            "Unable to read session line, it should have at least 2 parts between a ;"
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
        assert_eq!(result.session_status, SessionStatus::Running);

        let result = parse_line("ShortBreak;label".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::ShortBreak);

        let result = parse_line("LongBreak;label".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::LongBreak);

        let result = parse_line("Focus;label;paused".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::Focus);
        assert_eq!(result.session_status, SessionStatus::Paused);

        // Add timestamp of pause
        let result = parse_line("Focus;label;paused;8".to_owned()).unwrap();
        assert_eq!(result.label, "label");
        assert_eq!(result.session_type, SessionType::Focus);
        assert_eq!(result.session_status, SessionStatus::Paused);
        assert_eq!(result.elapsed_seconds, Some(8));
    }
}
