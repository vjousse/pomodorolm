module SessionStatus exposing
    ( SessionStatus(..)
    , toString
    )


type SessionStatus
    = NotStarted
    | Paused
    | Running


toString : SessionStatus -> String
toString sessionStatus =
    case sessionStatus of
        Paused ->
            "paused"

        Running ->
            "running"

        NotStarted ->
            "not_started"
