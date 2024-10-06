use pomodorolm_lib::pomodoro::{self, Config, Pomodoro, Session, SessionStatus, SessionType};

#[test]
fn it_defaults_the_way_it_should() {
    let pomodoro = Pomodoro::default();
    assert_eq!(pomodoro.current_work_round_number, 1);
    assert_eq!(
        pomodoro.current_session.session_type,
        pomodoro::SessionType::Focus
    );
    assert_eq!(
        pomodoro.current_session.status,
        pomodoro::SessionStatus::NotStarted
    );
}

#[test]
fn tick_should_not_do_anything_if_not_running() {
    let initial_state = Pomodoro::default();
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(initial_state, new_state);

    let new_state = pomodoro::pause(&Pomodoro::default());

    assert_eq!(
        initial_state.current_session.current_time,
        new_state.current_session.current_time
    );
}

#[test]
fn tick_should_tick_if_started() {
    let initial_state = pomodoro::play(&Pomodoro::default());
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );
}

#[test]
fn tick_should_return_next_session_at_end_of_turn() {
    let mut initial_state = pomodoro::play(&Pomodoro::default());
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
    let mut initial_state = pomodoro::play(&new_state);
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

    let mut new_state = pomodoro::tick(&pomodoro::play(&new_state));

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
    let new_state = pomodoro::tick(&pomodoro::play(&new_state));

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(new_state.current_work_round_number, 1);
}

#[test]
fn reset_should_stop_the_current_round() {
    let initial_state = pomodoro::play(&Pomodoro::default());
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(
        new_state.current_session.current_time,
        initial_state.current_session.current_time + 1
    );

    let new_state = pomodoro::reset(&new_state);

    assert_eq!(new_state.current_session.current_time, 0);
    assert_eq!(new_state.current_session.status, SessionStatus::NotStarted);
    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
}

#[test]
fn auto_start_should_run_next_state() {
    let pomodoro_with_auto_start_short_break = Pomodoro {
        config: Config {
            auto_start_short_break_timer: true,
            ..Default::default()
        },
        ..Default::default()
    };
    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_short_break);
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

    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_long_break);
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
    let mut initial_state = pomodoro::play(&pomodoro_with_auto_start_focus);
    initial_state.current_session.current_time = initial_state.config.short_break_duration - 1;

    // At the end of a break, we should switch to a focus session
    // that should run automatically
    let new_state = pomodoro::tick(&initial_state);

    assert_eq!(new_state.current_session.session_type, SessionType::Focus);
    assert_eq!(new_state.current_session.status, SessionStatus::Running);
}
