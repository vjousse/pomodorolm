module Pomodoro exposing
    ( Session
    , State
    )

import Seconds exposing (Seconds)
import SessionStatus exposing (SessionStatus)
import SessionType exposing (SessionType)


type alias State =
    { currentSession : Session
    , currentWorkRoundNumber : Int
    }


type alias Session =
    { currentTime : Seconds
    , sessionType : SessionType
    , status : SessionStatus
    }
