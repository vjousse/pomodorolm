use pomodorolm_lib::pomodoro::{
    self, Config, Pomodoro, Session, SessionInfo, SessionStatus, SessionType, create_session_file,
};
use std::fs;
use std::time::{Duration, SystemTime};
use tempfile::NamedTempFile;

fn get_initial_state() -> Pomodoro {
    Pomodoro {
        config: Config {
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
        },
        current_session: Session::default(),
        current_work_round_number: 1,
    }
}

#[test]
fn it_defaults_the_way_it_should() {
    let pomodoro = get_initial_state();

    assert_eq!(pomodoro.current_work_round_number, 1);
    assert_eq!(
        pomodoro.current_session.session_type,
        pomodoro::SessionType::Focus
    );
    assert_eq!(
        pomodoro.current_session.status,
        pomodoro::SessionStatus::NotStarted
    );

    assert_eq!(pomodoro.current_session.session_file, None);
}

#[test]
fn tick_should_not_do_anything_if_not_running() {
    let initial_state = get_initial_state();
    let new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(initial_state.clone(), new_state);
}

#[test]
fn tick_should_start_session_if_file_created() {
    let initial_state = get_initial_state();
    let _ = create_session_file(&initial_state);
    let new_state = pomodoro::tick(&initial_state).unwrap();
    assert_eq!(
        new_state,
        Pomodoro {
            current_session: Session {
                // Session should be running
                status: SessionStatus::Running,
                label: initial_state.current_session.label.clone(),
                // Session file should have been set
                session_file: Some(initial_state.config.session_file.clone()),
                start_time: new_state.current_session.start_time,
                ..initial_state.current_session
            },
            config: initial_state.config.clone(),
            ..initial_state
        }
    );

    // Start time should have been set
    assert!(new_state.current_session.start_time.is_some());

    // Session file should have been created
    assert!(
        new_state
            .current_session
            .session_file
            .as_ref()
            .unwrap()
            .exists()
    );
}

#[test]
fn pause_should_change_session_status() {
    let initial_state = get_initial_state();

    // It should pause the session status
    let new_state = pomodoro::pause(&initial_state);

    assert_eq!(
        new_state,
        Pomodoro {
            current_session: Session {
                status: SessionStatus::Paused,
                label: initial_state.current_session.label.clone(),
                session_file: initial_state.current_session.session_file.clone(),
                ..initial_state.current_session
            },
            config: initial_state.config.clone(),
            ..initial_state
        }
    );
}

#[test]
fn tick_should_tick_if_started() {
    let initial_state = pomodoro::play(&get_initial_state()).unwrap();
    let new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );
}

#[test]
fn play_should_create_session_file() {
    let play_state = pomodoro::play_with_session_file(&get_initial_state(), None).unwrap();

    assert!(play_state.current_session.session_file.is_some());
    assert!(play_state.current_session.session_file.unwrap().exists());
}

#[test]
fn tick_should_return_next_session_at_end_of_turn() {
    let mut initial_state = pomodoro::play(&get_initial_state()).unwrap();

    initial_state.current_session.current_time = initial_state.config.focus_duration - 1;

    // As the session is started, the session file should have been created
    assert!(initial_state.current_session.session_file.is_some());

    // At the end of a focus session, we should switch to a short break
    let new_state = pomodoro::tick(&initial_state).unwrap();
    assert_eq!(
        new_state.current_session.session_type,
        SessionType::ShortBreak
    );
    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);

    // As the ShortBreak session is not started, the session file should have been removed
    assert_eq!(new_state.current_session.session_file, None);

    // A work round includes a Focus and a Break, so the counter should be incremented only
    // at the end of a break
    assert_eq!(
        new_state.current_work_round_number,
        initial_state.current_work_round_number
    );

    // At the end of a short break round, we should switch to a focus round and
    // increment the current_work_round_number counter
    let mut initial_state = pomodoro::play(&new_state).unwrap();
    initial_state.current_session.current_time = initial_state.config.short_break_duration - 1;
    assert!(initial_state.current_session.session_file.is_some());

    let mut new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(
        new_state.current_work_round_number,
        initial_state.current_work_round_number + 1
    );
    assert!(new_state.current_session.session_file.is_none());

    // We are at the end of the last focus session, we should switch to a long break
    new_state.current_work_round_number = new_state.config.max_focus_rounds;
    new_state.current_session.current_time = new_state.config.focus_duration - 1;
    let pomodoro_play = &pomodoro::play(&new_state).unwrap();

    let mut new_state = pomodoro::tick(pomodoro_play).unwrap();

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(
        new_state.current_session.session_type,
        SessionType::LongBreak
    );
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(
        new_state.current_work_round_number,
        new_state.config.max_focus_rounds
    );

    // We are at the end of the long break, we should reset to a focus session
    new_state.current_session.current_time = new_state.config.long_break_duration - 1;
    let new_state = pomodoro::tick(&pomodoro::play(&new_state).unwrap()).unwrap();

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(new_state.current_work_round_number, 1);
}

#[test]
fn reset_should_stop_the_current_round() {
    let initial_state = pomodoro::play_with_session_file(&get_initial_state(), None).unwrap();
    let new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );

    let session_file = new_state.current_session.session_file.clone().unwrap();

    assert!(session_file.exists());
    let new_state = pomodoro::reset_round(&new_state).unwrap();

    // Reset should delete the file on disk
    assert!(!session_file.exists());

    assert_eq!(new_state.current_session.session_file, None);
    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
}

#[test]
fn auto_start_should_run_next_state() {
    let mut pomodoro_with_auto_start_short_break = get_initial_state();
    pomodoro_with_auto_start_short_break
        .config
        .auto_start_short_break_timer = true;

    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_short_break).unwrap();
    initial_state.current_session.current_time = initial_state.config.focus_duration - 1;

    // At the end of a focus session, we should switch to a short break
    // that should run automatically
    let new_state = pomodoro::tick(&initial_state).unwrap();
    assert_eq!(
        new_state.current_session.session_type,
        SessionType::ShortBreak
    );
    assert_eq!(new_state.current_session.status, SessionStatus::Running);

    let pomodoro_with_auto_start_long_break = Pomodoro {
        config: Config {
            auto_start_long_break_timer: true,
            ..Default::default()
        },
        current_work_round_number: 4,
        ..Default::default()
    };

    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_long_break).unwrap();
    initial_state.current_session.current_time = initial_state.config.focus_duration - 1;

    // At the end of the 4th focus session, we should switch to a long break
    // that should run automatically
    let new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(
        new_state.current_session.session_type,
        SessionType::LongBreak
    );
    assert_eq!(new_state.current_session.status, SessionStatus::Running);

    let pomodoro_with_auto_start_focus = Pomodoro {
        config: Config {
            auto_start_focus_timer: true,
            ..Default::default()
        },
        current_session: Session {
            session_type: SessionType::ShortBreak,
            ..Default::default()
        },

        ..Default::default()
    };
    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_focus).unwrap();
    initial_state.current_session.current_time = initial_state.config.short_break_duration - 1;

    // At the end of a break, we should switch to a focus session
    // that should run automatically
    let new_state = pomodoro::tick(&initial_state).unwrap();

    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::Running);
}

#[test]
fn tick_with_file_session_info_test() {
    let pomodoro_state = get_initial_state();

    let now = SystemTime::now();
    let session_info = SessionInfo {
        label: "Test label".to_string(),
        start_time: now,
        session_type: SessionType::Focus,
    };

    let new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    // If we have a new file we should start the pomodoro
    assert_eq!(new_state.current_session.status, SessionStatus::Running);

    let new_state = pomodoro::tick_with_file_session_info(&pomodoro_state, None).unwrap();

    // If we did remove the file, the pomodoro should be stopped
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);

    // Start it again
    let session_info = SessionInfo {
        label: "Test label".to_string(),
        start_time: now,
        session_type: SessionType::Focus,
    };

    let mut new_state =
        pomodoro::tick_with_file_session_info(&pomodoro_state, Some(session_info)).unwrap();

    assert_eq!(new_state.current_session.status, SessionStatus::Running);

    // Lets tick for 90 seconds
    for _ in 1..=90 {
        new_state = pomodoro::tick(&new_state).unwrap();
    }

    assert_eq!(new_state.current_session.current_time, 90);
    let ninety_seconds = Duration::new(90, 0);

    // Read a new session file that has 90 seconds more as start time,
    // so we should reset the current pomodoro
    let new_start_time = now + ninety_seconds;

    let session_info = SessionInfo {
        label: "Test label".to_string(),
        start_time: new_start_time,
        session_type: SessionType::Focus,
    };

    let new_state = pomodoro::tick_with_file_session_info(&new_state, Some(session_info)).unwrap();

    assert_eq!(new_state.current_session.status, SessionStatus::Running);
    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.start_time, Some(new_start_time));
}

#[test]
fn get_session_info_with_default_test() {
    let pomodoro = get_initial_state();
    let session_info =
        pomodoro::get_session_info_with_default(&pomodoro.config.session_file, &pomodoro);

    assert_eq!(session_info.session_type, SessionType::Focus);
    assert_eq!(session_info.label, pomodoro.config.default_focus_label);
    // Default label
    assert_eq!(session_info.label, "Focus");

    let _ = create_session_file(&pomodoro);

    let session_info =
        pomodoro::get_session_info_with_default(&pomodoro.config.session_file, &pomodoro);

    assert_eq!(session_info.session_type, SessionType::Focus);
    assert_eq!(session_info.label, "working");

    let _ = fs::write(
        &pomodoro.config.session_file,
        format!("{};{}", SessionType::ShortBreak, "test"),
    );

    let session_info =
        pomodoro::get_session_info_with_default(&pomodoro.config.session_file, &pomodoro);

    assert_eq!(session_info.session_type, SessionType::ShortBreak);
    assert_eq!(session_info.label, "test");

    let _ = fs::write(&pomodoro.config.session_file, format!("{};{}", "-", ""));
    let session_info =
        pomodoro::get_session_info_with_default(&pomodoro.config.session_file, &pomodoro);

    assert_eq!(session_info.session_type, SessionType::Focus);
    assert_eq!(session_info.label, pomodoro.config.default_focus_label);
    // Default label
    assert_eq!(session_info.label, "Focus");
}

#[test]
fn get_next_pomodoro_from_session_file_test() {
    let pomodoro = get_initial_state();
    let next_pomodoro =
        pomodoro::get_next_pomodoro_from_session_file(&pomodoro.config.session_file, &pomodoro)
            .unwrap();

    // No session file, the pomodoro should not be started
    assert_eq!(
        next_pomodoro.current_session.status,
        SessionStatus::NotStarted
    );

    let _ = create_session_file(&next_pomodoro);

    let next_pomodoro =
        pomodoro::get_next_pomodoro_from_session_file(&pomodoro.config.session_file, &pomodoro)
            .unwrap();

    // A session file was created, the pomodoro should be running
    assert_eq!(next_pomodoro.current_session.status, SessionStatus::Running);

    assert_eq!(
        next_pomodoro.current_session.session_type,
        SessionType::Focus
    );

    assert_eq!(
        next_pomodoro.current_session.session_file,
        Some(pomodoro.config.session_file.clone())
    );

    fs::remove_file(&pomodoro.config.session_file).unwrap();

    let next_pomodoro =
        pomodoro::get_next_pomodoro_from_session_file(&pomodoro.config.session_file, &pomodoro)
            .unwrap();

    // The session file was removed, the pomodoro should be stopped
    assert_eq!(
        next_pomodoro.current_session.status,
        SessionStatus::NotStarted
    );

    assert_eq!(
        next_pomodoro.current_session.session_type,
        SessionType::Focus
    );

    assert_eq!(next_pomodoro.current_session.session_file, None);

    // Session file should not exist
    assert!(!next_pomodoro.config.session_file.exists());

    // Play the pomodoro and create the related session file
    let next_pomodoro = pomodoro::play_with_session_file(&next_pomodoro, None).unwrap();

    assert_eq!(next_pomodoro.current_session.status, SessionStatus::Running);

    assert_eq!(
        next_pomodoro.current_session.session_type,
        SessionType::Focus
    );

    assert_eq!(
        next_pomodoro.current_session.session_file,
        Some(pomodoro.config.session_file.clone())
    );

    // Session file should exist
    assert!(
        next_pomodoro
            .current_session
            .session_file
            .clone()
            .unwrap()
            .exists()
    );

    // Stop / reset the pomodoro
    let next_pomodoro = pomodoro::reset(&next_pomodoro).unwrap();

    assert_eq!(next_pomodoro.current_session.session_file, None);

    // Session file should not exist anymore
    assert!(!next_pomodoro.config.session_file.clone().exists());
}
