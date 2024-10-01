use serde::{Deserialize, Serialize};

#[derive(Copy, Debug, Serialize, Deserialize, Clone)]
pub enum SessionState {
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

type Seconds = u16;

#[derive(Copy, Debug, Serialize, Deserialize, Clone)]
pub struct Config {
    pub auto_start_long_break_timer: bool,
    pub auto_start_short_break_timer: bool,
    pub auto_start_focus_timer: bool,
    pub focus_duration: Seconds,
    pub long_break_duration: Seconds,
    pub max_focus_rounds: u16,
    pub short_break_duration: Seconds,
}

#[derive(Copy, Debug, Serialize, Deserialize, Clone)]
pub struct Pomodoro<'a> {
    pub config: Config,
    #[serde(borrow)]
    pub current_session: Session<'a>,
    pub focus_round_number_over: u16,
}

impl Default for Pomodoro<'_> {
    fn default() -> Self {
        Pomodoro {
            config: Config {
                auto_start_long_break_timer: false,
                auto_start_short_break_timer: false,
                auto_start_focus_timer: false,
                focus_duration: 25 * 60,
                long_break_duration: 20 * 60,
                max_focus_rounds: 4,
                short_break_duration: 5 * 60,
            },
            current_session: Session::default(),
            focus_round_number_over: 0,
        }
    }
}
impl Pomodoro<'_> {
    pub fn duration_of_session(&self, session: Session) -> Seconds {
        match session.session_type {
            SessionType::Focus => self.config.focus_duration,
            SessionType::LongBreak => self.config.long_break_duration,
            SessionType::ShortBreak => self.config.short_break_duration,
        }
    }
}

#[derive(Copy, Debug, Serialize, Deserialize, Clone)]
pub struct Session<'a> {
    current_time: Seconds,
    label: Option<&'a str>,
    session_type: SessionType,
    state: SessionState,
}
impl Session<'_> {
    fn from_type(session_type: SessionType) -> Self {
        let mut session = Session::default();
        session.session_type = session_type;
        session
    }
}
impl Default for Session<'_> {
    fn default() -> Self {
        Session {
            current_time: 0,
            label: None,
            session_type: SessionType::Focus,
            state: SessionState::NotStarted,
        }
    }
}

pub fn pause<'a>(pomodoro: &Pomodoro<'a>) -> Pomodoro<'a> {
    Pomodoro {
        current_session: Session {
            state: SessionState::Paused,
            ..pomodoro.current_session
        },
        ..*pomodoro
    }
}

pub fn play<'a>(pomodoro: &Pomodoro<'a>) -> Pomodoro<'a> {
    Pomodoro {
        current_session: Session {
            state: SessionState::Running,
            ..pomodoro.current_session
        },
        ..*pomodoro
    }
}

pub fn get_next_session<'a>(pomodoro: &Pomodoro<'a>) -> Session<'a> {
    let session = pomodoro.current_session;
    match session.session_type {
        SessionType::Focus => {
            if pomodoro.focus_round_number_over + 1 == pomodoro.config.max_focus_rounds {
                Session::from_type(SessionType::LongBreak)
            } else {
                Session::from_type(SessionType::ShortBreak)
            }
        }
        _ => Session {
            session_type: SessionType::Focus,
            ..Session::default()
        },
    }
}

pub fn next<'a>(pomodoro: &Pomodoro<'a>) -> Pomodoro<'a> {
    Pomodoro {
        current_session: get_next_session(pomodoro),
        focus_round_number_over: match pomodoro.current_session.session_type {
            SessionType::Focus => pomodoro.focus_round_number_over + 1,
            SessionType::LongBreak => 0,
            _ => pomodoro.focus_round_number_over,
        },
        ..*pomodoro
    }
}

pub fn tick<'a>(pomodoro: &Pomodoro<'a>) -> Pomodoro<'a> {
    let session = pomodoro.current_session;

    match session.state {
        // Tick should do something only if the current session is in runnig mode
        SessionState::Running => {
            // If it was the last tick, return the next state
            let is_end_of_session =
                session.current_time + 1 == pomodoro.duration_of_session(session);

            if is_end_of_session {
                // Increment the number round counter if it was a focus session
                let focus_round_number_over = if session.session_type == SessionType::Focus {
                    pomodoro.focus_round_number_over + 1
                } else {
                    pomodoro.focus_round_number_over
                };

                let current_session = get_next_session(pomodoro);

                return Pomodoro {
                    focus_round_number_over,
                    current_session,
                    ..*pomodoro
                };
            }

            // If we're not a the end of a session, just update the time of the current session
            Pomodoro {
                current_session: Session {
                    current_time: session.current_time + 1,
                    ..pomodoro.current_session
                },
                ..*pomodoro
            }
        }
        _ => pomodoro.clone(),
    }
}