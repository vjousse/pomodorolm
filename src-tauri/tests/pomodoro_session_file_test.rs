use pomodorolm_lib::pomodoro::{
    self, Config, Pomodoro, Session, SessionInfo, SessionStatus, SessionType,
};
use tempfile::NamedTempFile;

fn get_config() -> Config {
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
        // Be sure that the tests can be run in //
        // by using an unique session_file per test
        session_file: NamedTempFile::new().unwrap().path().to_path_buf(),
        short_break_duration: 5 * 60,
    }
}
fn get_initial_state() -> Pomodoro {
    Pomodoro {
        config: get_config(),
        current_session: Session::default(),
        current_work_round_number: 1,
    }
}

fn get_running_state() -> Pomodoro {
    let config = get_config();
    Pomodoro {
        config: config.clone(),
        current_session: Session {
            // 5 minutes
            elapsed_seconds: 300,
            label: None,
            session_file: Some(config.session_file),
            session_type: SessionType::Focus,
            status: SessionStatus::Running,
        },
        current_work_round_number: 1,
    }
}

#[test]
fn tick_with_file_session_info_start_test() {
    let pomodoro_state = get_initial_state();

    let session_info = SessionInfo {
        elapsed_seconds: 0,
        label: "Test label".to_string(),
        session_status: SessionStatus::Running,
        session_type: SessionType::Focus,
    };

    // Be sure we have no starting file
    assert!(pomodoro_state.current_session.session_file.is_none());

    let new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    // If we have a new file we should start the pomodoro
    assert_eq!(new_state.current_session.status, SessionStatus::Running);
    assert!(new_state.current_session.session_file.is_some());

    // If we did remove the file, the pomodoro should be stopped
    let new_state = pomodoro::tick_with_file_session_info(&pomodoro_state, None).unwrap();

    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert!(new_state.current_session.session_file.is_none());

    // Start it again
    let session_info = SessionInfo {
        elapsed_seconds: 0,
        label: "Test label".to_string(),
        session_status: SessionStatus::Running,
        session_type: SessionType::Focus,
    };

    let new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    assert_eq!(new_state.current_session.status, SessionStatus::Running);
    assert!(new_state.current_session.session_file.is_some());
}

#[test]
fn tick_with_file_session_info_running_test() {
    let pomodoro_state = get_running_state();

    let session_info = SessionInfo {
        // 5 minutes
        elapsed_seconds: 300,
        label: "Test label".to_string(),
        session_status: SessionStatus::Running,
        session_type: SessionType::Focus,
    };

    let new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    // If we have a new file we should start the pomodoro
    assert_eq!(new_state.current_session.status, SessionStatus::Running);
    assert!(new_state.current_session.session_file.is_some());

    assert_eq!(new_state.current_session.elapsed_seconds, 301);
}

#[test]
fn tick_with_file_session_info_change_running_test() {
    let pomodoro_state = get_running_state();

    let session_info = SessionInfo {
        // 5 minutes
        elapsed_seconds: 200,
        label: "Test".to_string(),
        session_status: SessionStatus::Paused,
        session_type: SessionType::Focus,
    };

    let new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    // If we have a new file we should start the pomodoro
    assert_eq!(new_state.current_session.status, SessionStatus::Paused);
    assert!(new_state.current_session.session_file.is_some());

    assert_eq!(new_state.current_session.elapsed_seconds, 200);
    assert_eq!(new_state.current_session.label, Some("Test".to_string()));
}
