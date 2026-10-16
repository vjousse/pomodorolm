module TimeHelper exposing (getCurrentMaxTime)

import Seconds exposing (Seconds)
import Types exposing (Config, PomodoroState, SessionType(..))


getCurrentMaxTime : Config -> PomodoroState -> Seconds
getCurrentMaxTime config state =
    case state.currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
