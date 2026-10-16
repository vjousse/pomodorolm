module TimeHelper exposing (getCurrentMaxTime)

import Pomodoro exposing (PomodoroSession)
import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))
import Types exposing (Config)


getCurrentMaxTime : Config -> PomodoroSession -> Seconds
getCurrentMaxTime config currentSession =
    case currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
