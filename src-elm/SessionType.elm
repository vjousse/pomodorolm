module SessionType exposing
    ( SessionType(..)
    , sessionTypeFromString
    , sessionTypeToString
    )


type SessionType
    = Focus
    | ShortBreak
    | LongBreak


sessionTypeToString : SessionType -> String
sessionTypeToString sessionType =
    case sessionType of
        Focus ->
            "Focus"

        ShortBreak ->
            "ShortBreak"

        LongBreak ->
            "LongBreak"


sessionTypeFromString : String -> Maybe SessionType
sessionTypeFromString string =
    case String.toLower string of
        "focus" ->
            Just Focus

        "shortbreak" ->
            Just ShortBreak

        "longbreak" ->
            Just LongBreak

        _ ->
            Nothing
