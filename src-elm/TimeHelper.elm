module TimeHelper exposing (getCurrentMaxTime)

import Pomodoro
import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))
import Types exposing (Config)


getCurrentMaxTime : Config -> Pomodoro.PomodoroSession -> Seconds
getCurrentMaxTime config currentSession =
    case currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
