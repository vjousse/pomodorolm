module Json exposing (elmMessageEncoder, externalMessageDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode as Encode
import Themes exposing (Theme, ThemeColors)
import Types exposing (Config, ConfigAndThemes, ElmMessage, ExternalMessage(..), RustSession, RustState, SessionStatus(..), SessionType(..))


elmMessageEncoder : ElmMessage -> Encode.Value
elmMessageEncoder elmMessage =
    Encode.object
        [ ( "name", Encode.string elmMessage.name )
        ]


themeColorsDecoder : Decode.Decoder ThemeColors
themeColorsDecoder =
    Decode.succeed ThemeColors
        |> Pipe.required "accent" Decode.string
        |> Pipe.required "background" Decode.string
        |> Pipe.required "background_light" Decode.string
        |> Pipe.required "background_lightest" Decode.string
        |> Pipe.required "focus_round" Decode.string
        |> Pipe.required "focus_round_end" Decode.string
        |> Pipe.required "focus_round_middle" Decode.string
        |> Pipe.required "foreground" Decode.string
        |> Pipe.required "foreground_darker" Decode.string
        |> Pipe.required "foreground_darkest" Decode.string
        |> Pipe.required "long_round" Decode.string
        |> Pipe.required "short_round" Decode.string


themeDecoder : Decode.Decoder Theme
themeDecoder =
    Decode.succeed Theme
        |> Pipe.required "colors" themeColorsDecoder
        |> Pipe.required "name" Decode.string


themesDecoder : Decode.Decoder (List Theme)
themesDecoder =
    Decode.list themeDecoder


configDecoder : Decode.Decoder Config
configDecoder =
    let
        fieldSet0 =
            Decode.map8 Config
                (Decode.field "always_on_top" Decode.bool)
                (Decode.field "auto_start_break_timer" Decode.bool)
                (Decode.field "auto_start_work_timer" Decode.bool)
                (Decode.field "desktop_notifications" Decode.bool)
                (Decode.field "long_break_duration" Decode.int)
                (Decode.field "max_round_number" Decode.int)
                (Decode.field "minimize_to_tray" Decode.bool)
                (Decode.field "minimize_to_tray_on_close" Decode.bool)
    in
    Decode.map7 (<|)
        fieldSet0
        (Decode.field "muted" Decode.bool)
        (Decode.field "pomodoro_duration" Decode.int)
        (Decode.field "short_break_duration" Decode.int)
        (Decode.field "theme" Decode.string)
        (Decode.field "tick_sounds_during_break" Decode.bool)
        (Decode.field "tick_sounds_during_work" Decode.bool)


configAndThemesDecoder : Decode.Decoder ConfigAndThemes
configAndThemesDecoder =
    Decode.succeed ConfigAndThemes
        |> Pipe.required "config" configDecoder
        |> Pipe.required "themes" themesDecoder


rustStateDecoder : Decode.Decoder RustState
rustStateDecoder =
    Decode.succeed RustState
        |> Pipe.required "current_session" rustSessionDecoder


sessionTypeFromStringDecoder : String -> Decode.Decoder SessionType
sessionTypeFromStringDecoder string =
    case String.toLower string of
        "focus" ->
            Decode.succeed Focus

        "shortbreak" ->
            Decode.succeed ShortBreak

        "longbreak" ->
            Decode.succeed LongBreak

        _ ->
            Decode.fail ("Unknown sessionType: " ++ string)


sessionTypeDecoder : Decode.Decoder SessionType
sessionTypeDecoder =
    Decode.string |> Decode.andThen sessionTypeFromStringDecoder


sessionStatusDecoder : Decode.Decoder SessionStatus
sessionStatusDecoder =
    Decode.string |> Decode.andThen sessionStatusFromStringDecoder


sessionStatusFromStringDecoder : String -> Decode.Decoder SessionStatus
sessionStatusFromStringDecoder string =
    case String.toLower string of
        "paused" ->
            Decode.succeed Paused

        "notstarted" ->
            Decode.succeed NotStarted

        "running" ->
            Decode.succeed Running

        _ ->
            Decode.fail ("Unknown sessionStatus: " ++ string)


rustSessionDecoder : Decode.Decoder RustSession
rustSessionDecoder =
    Decode.succeed RustSession
        |> Pipe.required "current_time" Decode.int
        |> Pipe.optional "label" (Decode.maybe Decode.string) Nothing
        |> Pipe.required "session_type" sessionTypeDecoder
        |> Pipe.required "state" sessionStatusDecoder


externalMessageDecoder : Decode.Decoder ExternalMessage
externalMessageDecoder =
    Decode.oneOf
        [ rustStateDecoder |> Decode.map RustStateMsg
        , configAndThemesDecoder |> Decode.map RustConfigAndThemesMsg
        ]
