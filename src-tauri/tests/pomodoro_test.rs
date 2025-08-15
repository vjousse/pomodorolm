use pomodorolm_lib::pomodoro::{self, Config, Pomodoro, Session, SessionStatus, SessionType};
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
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(initial_state.clone(), new_state);
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
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );
}

#[test]
fn play_should_create_session_file() {
    let play_state = pomodoro::play(&get_initial_state()).unwrap();

    assert!(play_state.current_session.session_file.is_some());
    assert!(play_state.current_session.session_file.unwrap().exists());
}

#[test]
fn tick_should_return_next_session_at_end_of_turn() {
    let mut initial_state = pomodoro::play(&get_initial_state()).unwrap();
    initial_state.current_session.current_time = initial_state.config.focus_duration - 1;

    // At the end of a focus session, we should switch to a short break
    let new_state = pomodoro::tick(&initial_state);
    assert_eq!(
        new_state.current_session.session_type,
        SessionType::ShortBreak
    );
    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
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

    let mut new_state = pomodoro::tick(&initial_state);

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(
        new_state.current_work_round_number,
        initial_state.current_work_round_number + 1
    );

    // We are at the end of the last focus session, we should switch to a long break
    new_state.current_work_round_number = new_state.config.max_focus_rounds;
    new_state.current_session.current_time = new_state.config.focus_duration - 1;

    let mut new_state = pomodoro::tick(&pomodoro::play(&new_state).unwrap());

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
    let new_state = pomodoro::tick(&pomodoro::play(&new_state).unwrap());

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(new_state.current_work_round_number, 1);
}

#[test]
fn reset_should_stop_the_current_round() {
    let initial_state = pomodoro::play(&get_initial_state()).unwrap();
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );

    assert!(new_state
        .current_session
        .session_file
        .clone()
        .unwrap()
        .exists());
    let new_state = pomodoro::reset_round(&new_state).unwrap();

    // Reset should delete the file on disk
    assert!(!new_state
        .current_session
        .session_file
        .clone()
        .unwrap()
        .exists());

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
    let new_state = pomodoro::tick(&initial_state);
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
    let new_state = pomodoro::tick(&initial_state);

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
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::Running);
}
