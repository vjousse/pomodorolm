module SessionType exposing
    ( SessionType(..)
    , fromString
    , toString
    )


type SessionType
    = Focus
    | ShortBreak
    | LongBreak


toString : SessionType -> String
toString sessionType =
    case sessionType of
        Focus ->
            "Focus"

        ShortBreak ->
            "ShortBreak"

        LongBreak ->
            "LongBreak"


fromString : String -> Maybe SessionType
fromString string =
    case String.toLower string of
        "focus" ->
            Just Focus

        "shortbreak" ->
            Just ShortBreak

        "longbreak" ->
            Just LongBreak

        _ ->
            Nothing
