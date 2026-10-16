module TimeHelper exposing (getCurrentMaxTime)

import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))
import Types exposing (Config, PomodoroSession)


getCurrentMaxTime : Config -> PomodoroSession -> Seconds
getCurrentMaxTime config currentSession =
    case currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
