module TimeHelper exposing (getCurrentMaxTime)

import Types exposing (Config, RustState, Seconds, SessionType(..))


getCurrentMaxTime : Config -> RustState -> Seconds
getCurrentMaxTime config state =
    case state.currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
