module SessionStatus exposing
    ( SessionStatus(..)
    , sessionStatusToString
    )


type SessionStatus
    = NotStarted
    | Paused
    | Running


sessionStatusToString : SessionStatus -> String
sessionStatusToString sessionStatus =
    case sessionStatus of
        Paused ->
            "paused"

        Running ->
            "running"

        NotStarted ->
            "not_started"
