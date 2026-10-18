module TimeHelper exposing (getCurrentMaxTime)

import Pomodoro
import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))


getCurrentMaxTime :
    { config
        | focusDuration : Seconds
        , longBreakDuration : Seconds
        , shortBreakDuration : Seconds
    }
    -> Pomodoro.Session
    -> Seconds
getCurrentMaxTime config currentSession =
    case currentSession.sessionType of
        Focus ->
            config.focusDuration

        LongBreak ->
            config.longBreakDuration

        ShortBreak ->
            config.shortBreakDuration
