module TimeHelper exposing (getCurrentMaxTime)

import Types exposing (Config, PomodoroState, Seconds, SessionType(..))


getCurrentMaxTime : Config -> PomodoroState -> Seconds
getCurrentMaxTime config state =
    case state.currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
