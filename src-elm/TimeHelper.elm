module TimeHelper exposing (getCurrentMaxTime)

import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))
import Types exposing (Config, PomodoroState)


getCurrentMaxTime : Config -> PomodoroState -> Seconds
getCurrentMaxTime config state =
    case state.currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
