port module Main exposing (Flags, main)

import Browser
import ColorHelper exposing (colorForSessionType, computeCurrentColor, fromCSSHexToRGB, fromRGBToCSSHex)
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Json exposing (configEncoder, currentStateEncoder, elmMessageBuilder, elmMessageEncoder, externalMessageDecoder, sessionTypeDecoder, soundMessageEncoder)
import Json.Decode as Decode
import Json.Encode as Encode
import ListWithCurrent exposing (ListWithCurrent(..))
import Themes exposing (ThemeColors, pomodorolmTheme)
import TimeHelper exposing (getCurrentMaxTime)
import Types
    exposing
        ( Config
        , Defaults
        , ExternalMessage(..)
        , Model
        , Msg(..)
        , Notification
        , RGB(..)
        , Seconds
        , SessionStatus(..)
        , SessionType(..)
        , Setting(..)
        , SettingTab(..)
        , SettingType(..)
        , sessionTypeFromString
        , sessionTypeToString
        )
import View.Drawer
import View.Nav
import View.Timer


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Flags =
    { alwaysOnTop : Bool
    , appVersion : String
    , autoQuit : Maybe String
    , autoStartBreakTimer : Bool
    , autoStartOnAppStartup : Bool
    , autoStartWorkTimer : Bool
    , defaultFocusLabel : String
    , defaultShortBreakLabel : String
    , defaultLongBreakLabel : String
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , muted : Bool
    , focusDuration : Seconds
    , shortBreakDuration : Seconds
    , startMinimized : Bool
    , systemStartupAutoStart : Bool
    , theme : String
    , tickSoundsDuringWork : Bool
    , tickSoundsDuringBreak : Bool
    }


defaults : Defaults
defaults =
    { longBreakDuration = 20 * 60
    , pomodoroDuration = 25 * 60
    , shortBreakDuration = 5 * 60
    , maxRoundNumber = 4
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        theme =
            pomodorolmTheme

        currentState =
            { color = theme.colors.focusRound
            , percentage = 1
            , paused = False
            , sessionStatus = NotStarted
            }
    in
    ( { appVersion = flags.appVersion
      , config =
            { alwaysOnTop = flags.alwaysOnTop
            , autoQuit =
                flags.autoQuit
                    |> Maybe.andThen
                        (\v ->
                            Decode.decodeString sessionTypeDecoder v
                                |> Result.toMaybe
                        )
            , autoStartBreakTimer = flags.autoStartBreakTimer
            , autoStartOnAppStartup = flags.autoStartOnAppStartup
            , autoStartWorkTimer = flags.autoStartWorkTimer
            , defaultFocusLabel = flags.defaultFocusLabel
            , defaultLongBreakLabel = flags.defaultLongBreakLabel
            , defaultShortBreakLabel = flags.defaultShortBreakLabel
            , desktopNotifications = flags.desktopNotifications
            , focusAudio = Nothing
            , focusDuration = flags.focusDuration
            , longBreakAudio = Nothing
            , longBreakDuration = flags.longBreakDuration
            , maxRoundNumber = flags.maxRoundNumber
            , minimizeToTray = flags.minimizeToTray
            , minimizeToTrayOnClose = flags.minimizeToTrayOnClose
            , muted = flags.muted
            , shortBreakAudio = Nothing
            , shortBreakDuration = flags.shortBreakDuration
            , startMinimized = flags.startMinimized
            , systemStartupAutoStart = flags.systemStartupAutoStart
            , theme = flags.theme
            , tickSoundsDuringWork = flags.tickSoundsDuringWork
            , tickSoundsDuringBreak = flags.tickSoundsDuringBreak
            }
      , currentColor = fromCSSHexToRGB theme.colors.focusRound
      , currentState = currentState
      , drawerOpen = False
      , focusLabel = flags.defaultFocusLabel
      , longBreakLabel = flags.defaultLongBreakLabel
      , pomodoroState = Nothing
      , settingTab = TimerTab
      , shortBreakLabel = flags.defaultShortBreakLabel
      , strokeDasharray = 691.3321533203125
      , theme = theme
      , themes = EmptyListWithCurrent
      , volume = 1
      , volumeSliderHidden = True
      }
    , Cmd.batch
        [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
        , sendMessageFromElm (elmMessageEncoder { name = "get_init_data", value = Nothing })
        , setThemeColors <| theme.colors
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config } as model) =
    case msg of
        AudioFileRequested sessionType ->
            ( model
            , sendMessageFromElm
                (elmMessageEncoder
                    { name = "choose_sound_file"
                    , value = Just <| sessionTypeToString sessionType
                    }
                )
            )

        ChangeSettingTab settingTab ->
            ( { model | settingTab = settingTab }, Cmd.none )

        ChangeTheme theme ->
            let
                currentState =
                    model.currentState

                newState =
                    { currentState
                        | color =
                            fromRGBToCSSHex
                                (model.pomodoroState
                                    |> Maybe.map (\state -> colorForSessionType state.currentSession.sessionType theme)
                                    |> Maybe.withDefault (fromCSSHexToRGB <| theme.colors.focusRound)
                                )
                    }

                newConfig =
                    { config
                        | theme = theme.name |> String.toLower
                    }
            in
            ( { model
                | config = newConfig
                , currentState = newState
                , theme = theme
              }
            , Cmd.batch
                [ setThemeColors theme.colors
                , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
                , sendMessageFromElm (elmMessageBuilder "update_current_state" newState currentStateEncoder)
                ]
            )

        CloseWindow ->
            ( model
            , if model.config.minimizeToTrayOnClose then
                hideWindow ()

              else
                closeWindow ()
            )

        HideVolumeBar ->
            ( { model | volumeSliderHidden = True }, Cmd.none )

        MinimizeWindow ->
            ( model
            , if model.config.minimizeToTray then
                hideWindow ()

              else
                minimizeWindow ()
            )

        NoOp ->
            ( model, Cmd.none )

        ProcessExternalMessage (InitDataMsg c) ->
            let
                updatedThemes =
                    c.themes
                        |> ListWithCurrent.fromList
                        |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == c.config.theme)

                newThemes =
                    case ListWithCurrent.getCurrent updatedThemes of
                        Just theme ->
                            -- We found a theme with the same name than in the config: everything's fine
                            if (theme.name |> String.toLower) == (c.config.theme |> String.toLower) then
                                updatedThemes

                            else
                                -- If we didn't found a corresponding theme name, pomodorolm should be the default theme
                                updatedThemes |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == "pomodorolm")

                        Nothing ->
                            updatedThemes

                ( newModel, newCmd ) =
                    { model
                        | config = c.config
                        , focusLabel = c.config.defaultFocusLabel
                        , longBreakLabel = c.config.defaultLongBreakLabel
                        , shortBreakLabel = c.config.defaultShortBreakLabel
                        , themes = newThemes
                    }
                        |> update (ProcessExternalMessage (RustStateMsg c.pomodoroState))

                ( modelWithTheme, cmdWithTheme ) =
                    case newThemes |> ListWithCurrent.getCurrent of
                        Just currentTheme ->
                            let
                                ( updatedModel, updatedCmd ) =
                                    update (ChangeTheme currentTheme) newModel
                            in
                            ( updatedModel, Cmd.batch [ updatedCmd, newCmd ] )

                        _ ->
                            ( newModel, newCmd )
            in
            -- Auto start if config is set
            if modelWithTheme.config.autoStartOnAppStartup then
                let
                    ( updatedModel, updatedCmd ) =
                        update TogglePlayStatus modelWithTheme
                in
                ( updatedModel, Cmd.batch [ cmdWithTheme, updatedCmd ] )

            else
                ( modelWithTheme, cmdWithTheme )

        ProcessExternalMessage (RustStateMsg pomodoroState) ->
            let
                getNotification : String -> String -> String -> Seconds -> RGB -> Notification
                getNotification title body name duration (RGB r g b) =
                    let
                        minutes =
                            (duration |> toFloat) / 60 |> round
                    in
                    { title = title
                    , body =
                        "Start a "
                            ++ String.fromInt minutes
                            ++ " minute"
                            ++ (if minutes > 1 then
                                    "s"

                                else
                                    ""
                               )
                            ++ " "
                            ++ body
                    , name = name
                    , red = r
                    , green = g
                    , blue = b
                    }

                getCmds : Config -> String -> String -> String -> String -> Seconds -> RGB -> Bool -> List (Cmd Msg)
                getCmds { desktopNotifications, muted } soundName title body name duration rgb quit =
                    [ if desktopNotifications then
                        notify <| getNotification title body name duration rgb

                      else
                        Cmd.none
                    , if muted then
                        if quit then
                            sendMessageFromElm (elmMessageEncoder { name = "quit", value = Nothing })

                        else
                            Cmd.none

                      else
                        sendMessageFromElm (elmMessageBuilder "play_sound" { soundId = soundName, quitAfterPlay = quit } soundMessageEncoder)
                    ]

                maxTime =
                    getCurrentMaxTime config pomodoroState

                currentColor =
                    computeCurrentColor pomodoroState.currentSession.currentTime maxTime pomodoroState.currentSession.sessionType model.theme

                percent =
                    if maxTime /= 0 then
                        toFloat (maxTime - pomodoroState.currentSession.currentTime) / toFloat maxTime

                    else
                        1

                currentState =
                    { color = fromRGBToCSSHex currentColor
                    , percentage = percent
                    , paused =
                        pomodoroState.currentSession.status == Paused
                    , sessionStatus = pomodoroState.currentSession.status
                    }

                cmds =
                    model.pomodoroState
                        |> Maybe.map
                            (\state ->
                                -- If we’ve changed the session type
                                if state.currentSession.sessionType /= pomodoroState.currentSession.sessionType then
                                    case pomodoroState.currentSession.sessionType of
                                        Focus ->
                                            getCmds
                                                config
                                                "audio-work"
                                                (if state.currentSession.sessionType == ShortBreak then
                                                    "Short break completed"

                                                 else
                                                    "Long break completed"
                                                )
                                                "focus round"
                                                "start_focus"
                                                model.config.focusDuration
                                                currentColor
                                                ((config.autoQuit == Just ShortBreak && state.currentSession.sessionType == ShortBreak)
                                                    || (config.autoQuit == Just LongBreak && state.currentSession.sessionType == LongBreak)
                                                )

                                        LongBreak ->
                                            getCmds
                                                config
                                                "audio-long-break"
                                                "Focus round completed"
                                                "long break"
                                                "start_long_break"
                                                model.config.longBreakDuration
                                                currentColor
                                                False

                                        ShortBreak ->
                                            getCmds
                                                config
                                                "audio-short-break"
                                                "Focus round completed"
                                                "short break"
                                                "start_short_break"
                                                model.config.shortBreakDuration
                                                currentColor
                                                (config.autoQuit == Just Focus)

                                else
                                    []
                            )
                        |> Maybe.withDefault []
            in
            ( { model
                | currentColor = currentColor
                , currentState = currentState
                , pomodoroState = Just pomodoroState
              }
            , Cmd.batch
                (sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder) :: cmds)
            )

        ProcessExternalMessage (SoundFilePath sessionType path) ->
            let
                newConfig =
                    case sessionType of
                        Focus ->
                            { config | focusAudio = Just path }

                        ShortBreak ->
                            { config | shortBreakAudio = Just path }

                        LongBreak ->
                            { config | longBreakAudio = Just path }
            in
            ( { model | config = newConfig }
            , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
            )

        Reset ->
            let
                currentState =
                    { color =
                        fromRGBToCSSHex
                            (model.pomodoroState
                                |> Maybe.map (\state -> colorForSessionType state.currentSession.sessionType model.theme)
                                |> Maybe.withDefault (fromCSSHexToRGB <| model.theme.colors.focusRound)
                            )
                    , percentage = 1
                    , paused =
                        model.pomodoroState |> Maybe.map (\state -> state.currentSession.status == Paused) |> Maybe.withDefault False
                    , sessionStatus = NotStarted
                    }
            in
            ( model
            , Cmd.batch
                [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
                , sendMessageFromElm (elmMessageEncoder { name = "reset", value = Nothing })
                ]
            )

        ResetSettings ->
            let
                newConfig =
                    { config
                        | focusDuration = defaults.pomodoroDuration
                        , shortBreakDuration = defaults.shortBreakDuration
                        , longBreakDuration = defaults.longBreakDuration
                        , maxRoundNumber = defaults.maxRoundNumber
                    }
            in
            ( { model
                | config = newConfig
              }
            , Cmd.batch
                [ sendMessageFromElm (elmMessageEncoder { name = "reset", value = Nothing })
                ]
            )

        ResetAudioFile sessionType ->
            let
                newConfig =
                    case sessionType of
                        Focus ->
                            { config | focusAudio = Nothing }

                        ShortBreak ->
                            { config | shortBreakAudio = Nothing }

                        LongBreak ->
                            { config | longBreakAudio = Nothing }
            in
            ( { model
                | config = newConfig
              }
            , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
            )

        SkipCurrentRound ->
            ( model
            , sendMessageFromElm (elmMessageEncoder { name = "skip", value = Nothing })
            )

        ToggleDrawer ->
            let
                newConfig =
                    { config
                        | -- Avoid having impossible states
                          maxRoundNumber =
                            if model.config.maxRoundNumber == 0 then
                                1

                            else
                                model.config.maxRoundNumber
                        , focusDuration =
                            if model.config.focusDuration == 0 then
                                60

                            else
                                model.config.focusDuration
                        , shortBreakDuration =
                            if model.config.shortBreakDuration == 0 then
                                60

                            else
                                model.config.shortBreakDuration
                        , longBreakDuration =
                            if model.config.longBreakDuration == 0 then
                                60

                            else
                                model.config.longBreakDuration
                    }
            in
            ( { model
                | drawerOpen = not model.drawerOpen
                , config = newConfig
              }
            , Cmd.none
            )

        ToggleMute ->
            let
                newVolume =
                    if config.muted then
                        model.volume

                    else
                        0

                newConfig =
                    { config | muted = not config.muted }
            in
            ( { model | volume = newVolume, config = newConfig }
            , Cmd.batch
                [ setVolume newVolume
                , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
                ]
            )

        TogglePlayStatus ->
            model.pomodoroState
                |> Maybe.map
                    (\state ->
                        case state.currentSession.status of
                            Running ->
                                let
                                    maxTime =
                                        getCurrentMaxTime config state

                                    currentState =
                                        { color =
                                            fromRGBToCSSHex <|
                                                computeCurrentColor
                                                    state.currentSession.currentTime
                                                    (getCurrentMaxTime config state)
                                                    state.currentSession.sessionType
                                                    model.theme
                                        , percentage =
                                            if maxTime /= 0 then
                                                toFloat (maxTime - state.currentSession.currentTime) / toFloat maxTime

                                            else
                                                1
                                        , paused = True
                                        , sessionStatus = Paused
                                        }
                                in
                                ( { model | currentState = currentState }
                                , Cmd.batch
                                    [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
                                    , sendMessageFromElm (elmMessageEncoder { name = "pause", value = Nothing })
                                    ]
                                )

                            status ->
                                let
                                    maxTime =
                                        getCurrentMaxTime config state

                                    currentState =
                                        { color =
                                            fromRGBToCSSHex <|
                                                computeCurrentColor state.currentSession.currentTime
                                                    (getCurrentMaxTime config state)
                                                    state.currentSession.sessionType
                                                    model.theme
                                        , percentage =
                                            if maxTime /= 0 then
                                                toFloat (maxTime - state.currentSession.currentTime) / toFloat maxTime

                                            else
                                                1
                                        , paused = False
                                        , sessionStatus = status
                                        }
                                in
                                ( { model | currentState = currentState }
                                , Cmd.batch
                                    [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
                                    , sendMessageFromElm (elmMessageEncoder { name = "play", value = Nothing })
                                    ]
                                )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        UpdateLabel sessionType label ->
            ( case sessionType of
                Focus ->
                    { model | focusLabel = label }

                ShortBreak ->
                    { model | shortBreakLabel = label }

                LongBreak ->
                    { model | longBreakLabel = label }
            , Cmd.none
            )

        UpdateSetting settingType ->
            let
                toInt value =
                    case String.toInt value of
                        Nothing ->
                            0

                        Just stringValue ->
                            stringValue

                newConfig =
                    case settingType of
                        AutoQuit sessionTypeString ->
                            { config | autoQuit = sessionTypeFromString sessionTypeString }

                        FocusTime value ->
                            { config | focusDuration = min (90 * 60) (toInt value * 60) }

                        Label sessionType label ->
                            case sessionType of
                                Focus ->
                                    { config | defaultFocusLabel = label }

                                ShortBreak ->
                                    { config | defaultShortBreakLabel = label }

                                LongBreak ->
                                    { config | defaultLongBreakLabel = label }

                        LongBreakTime value ->
                            { config | longBreakDuration = min (90 * 60) (toInt value * 60) }

                        Rounds value ->
                            { config | maxRoundNumber = min 12 (toInt value) }

                        ShortBreakTime value ->
                            { config | shortBreakDuration = min (90 * 60) (toInt value * 60) }

                        Toggle value ->
                            case value of
                                AlwaysOnTop ->
                                    { config | alwaysOnTop = not config.alwaysOnTop }

                                AutoStartBreakTimer ->
                                    { config | autoStartBreakTimer = not config.autoStartBreakTimer }

                                AutoStartWorkTimer ->
                                    { config | autoStartWorkTimer = not config.autoStartWorkTimer }

                                AutoStartOnAppStartup ->
                                    { config | autoStartOnAppStartup = not config.autoStartOnAppStartup }

                                DesktopNotifications ->
                                    { config | desktopNotifications = not config.desktopNotifications }

                                MinimizeToTray ->
                                    { config | minimizeToTray = not config.minimizeToTray }

                                MinimizeToTrayOnClose ->
                                    { config | minimizeToTrayOnClose = not config.minimizeToTrayOnClose }

                                StartMinimized ->
                                    { config | startMinimized = not config.startMinimized }

                                SystemStartupAutoStart ->
                                    { config | systemStartupAutoStart = not config.systemStartupAutoStart }

                                TickSoundsDuringWork ->
                                    { config | tickSoundsDuringWork = not config.tickSoundsDuringWork }

                                TickSoundsDuringBreak ->
                                    { config | tickSoundsDuringBreak = not config.tickSoundsDuringBreak }
            in
            ( { model | config = newConfig }
            , Cmd.batch
                [ sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
                , sendMessageFromElm (elmMessageEncoder { name = "reset", value = Nothing })
                ]
            )

        UpdateVolume volumeStr ->
            let
                newVolume =
                    case String.toInt volumeStr of
                        Nothing ->
                            model.volume

                        Just v ->
                            toFloat v / 100

                newConfig =
                    { config | muted = newVolume <= 0 }
            in
            ( { model
                | volume = newVolume
                , config = newConfig
              }
            , setVolume newVolume
            )


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ View.Nav.navView model
        , if model.drawerOpen then
            View.Drawer.drawerView model

          else
            View.Timer.timerView model
        ]



-- SUBSCRIPTIONS


mapJsonMessage : Decode.Decoder a -> (a -> Msg) -> Decode.Value -> Msg
mapJsonMessage decoder msg value =
    case Decode.decodeValue decoder value of
        Ok model ->
            msg model

        Err _ ->
            --@FIX: don't fail silently
            NoOp


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ togglePlay (always TogglePlayStatus)
        , skip (always SkipCurrentRound)
        , sendMessageToElm (mapJsonMessage externalMessageDecoder ProcessExternalMessage)
        ]


port togglePlay : (() -> msg) -> Sub msg


port skip : (() -> msg) -> Sub msg


port sendMessageToElm : (Decode.Value -> msg) -> Sub msg



-- PORTS


port sendMessageFromElm : Encode.Value -> Cmd msg


port setVolume : Float -> Cmd msg


port closeWindow : () -> Cmd msg


port minimizeWindow : () -> Cmd msg


port hideWindow : () -> Cmd msg


port notify : Notification -> Cmd msg


port setThemeColors : ThemeColors -> Cmd msg
