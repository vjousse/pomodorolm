module Pomodoro exposing
    ( PomodoroSession
    , PomodoroState
    )

import Seconds exposing (Seconds)
import SessionStatus exposing (SessionStatus)
import SessionType exposing (SessionType)


type alias PomodoroState =
    { currentSession : PomodoroSession
    , currentWorkRoundNumber : Int
    }


type alias PomodoroSession =
    { currentTime : Seconds
    , label : Maybe String
    , sessionType : SessionType
    , status : SessionStatus
    }
