port module Main exposing (Flags, main)

import Browser
import ColorHelper exposing (colorForSessionType, computeCurrentColor, fromCSSHexToRGB, fromRGBToCSSHex)
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Json exposing (elmMessageEncoder, externalMessageDecoder)
import Json.Decode as Decode
import Json.Encode as Encode
import ListWithCurrent exposing (ListWithCurrent(..))
import Themes exposing (ThemeColors, pomodorolmTheme)
import TimeHelper exposing (getCurrentMaxTime)
import Types exposing (Config, CurrentState, Defaults, ExternalMessage(..), Model, Msg(..), Notification, RGB(..), Seconds, SessionStatus(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..), sessionTypeToString)
import View


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


sessionStatusToString : SessionStatus -> String
sessionStatusToString sessionStatus =
    case sessionStatus of
        Paused ->
            "paused"

        Running ->
            "running"

        NotStarted ->
            "not_started"


type alias Flags =
    { alwaysOnTop : Bool
    , appVersion : String
    , autoStartWorkTimer : Bool
    , autoStartBreakTimer : Bool
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , muted : Bool
    , focusDuration : Seconds
    , shortBreakDuration : Seconds
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
            }
    in
    ( { appVersion = flags.appVersion
      , config =
            { alwaysOnTop = flags.alwaysOnTop
            , autoStartWorkTimer = flags.autoStartWorkTimer
            , autoStartBreakTimer = flags.autoStartBreakTimer
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
            , theme = flags.theme
            , tickSoundsDuringWork = flags.tickSoundsDuringWork
            , tickSoundsDuringBreak = flags.tickSoundsDuringBreak
            }
      , currentColor = fromCSSHexToRGB theme.colors.focusRound
      , currentState = currentState
      , drawerOpen = False
      , pomodoroState = Nothing
      , settingTab = TimerTab
      , strokeDasharray = 691.3321533203125
      , theme = theme
      , themes = EmptyListWithCurrent
      , volume = 1
      , volumeSliderHidden = True
      }
    , Cmd.batch
        [ updateCurrentState currentState
        , updateSessionStatus (NotStarted |> sessionStatusToString)
        , sendMessageFromElm (elmMessageEncoder { name = "get-state", value = Nothing })
        , getConfigFromRust ()
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

        ChangeSettingConfig settingConfig ->
            let
                newSettingsConfig =
                    case settingConfig of
                        AlwaysOnTop ->
                            { config | alwaysOnTop = not config.alwaysOnTop }

                        AutoStartBreakTimer ->
                            { config | autoStartBreakTimer = not config.autoStartBreakTimer }

                        AutoStartWorkTimer ->
                            { config | autoStartWorkTimer = not config.autoStartWorkTimer }

                        TickSoundsDuringWork ->
                            { config | tickSoundsDuringWork = not config.tickSoundsDuringWork }

                        TickSoundsDuringBreak ->
                            { config | tickSoundsDuringBreak = not config.tickSoundsDuringBreak }

                        DesktopNotifications ->
                            { config | desktopNotifications = not config.desktopNotifications }

                        MinimizeToTray ->
                            { config | minimizeToTray = not config.minimizeToTray }

                        MinimizeToTrayOnClose ->
                            { config | minimizeToTrayOnClose = not config.minimizeToTrayOnClose }
            in
            ( { model | config = newSettingsConfig }
            , updateConfig newSettingsConfig
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
                , updateConfig newConfig
                , updateCurrentState newState
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

        ProcessExternalMessage (RustConfigAndThemesMsg c) ->
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

                newModel =
                    { model
                        | config = c.config
                        , themes = newThemes
                    }
            in
            case newThemes |> ListWithCurrent.getCurrent of
                Just currentTheme ->
                    let
                        ( updatedModel, cmds ) =
                            update (ChangeTheme currentTheme) newModel
                    in
                    ( updatedModel, Cmd.batch [ cmds, updateSessionStatus (NotStarted |> sessionStatusToString) ] )

                _ ->
                    ( newModel, updateSessionStatus (NotStarted |> sessionStatusToString) )

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

                getCmds : Config -> String -> String -> String -> String -> Seconds -> RGB -> List (Cmd Msg)
                getCmds { desktopNotifications, muted } soundName title body name duration rgb =
                    [ if desktopNotifications then
                        notify <| getNotification title body name duration rgb

                      else
                        Cmd.none
                    , if muted then
                        Cmd.none

                      else
                        playSound soundName
                    ]

                maxTime =
                    getCurrentMaxTime config pomodoroState

                currentColor =
                    computeCurrentColor pomodoroState.currentSession.currentTime maxTime pomodoroState.currentSession.sessionType model.theme

                percent =
                    toFloat (maxTime - pomodoroState.currentSession.currentTime) / toFloat maxTime

                currentState =
                    { color = fromRGBToCSSHex currentColor
                    , percentage = percent
                    , paused =
                        pomodoroState.currentSession.status == Paused
                    }

                cmds =
                    model.pomodoroState
                        |> Maybe.map
                            (\state ->
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

                                        LongBreak ->
                                            getCmds
                                                config
                                                "audio-long-break"
                                                "Focus round completed"
                                                "long break"
                                                "start_long_break"
                                                model.config.longBreakDuration
                                                currentColor

                                        ShortBreak ->
                                            getCmds
                                                config
                                                "audio-short-break"
                                                "Focus round completed"
                                                "short break"
                                                "start_short_break"
                                                model.config.shortBreakDuration
                                                currentColor

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
            , Cmd.batch (updateCurrentState currentState :: cmds)
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
            , updateConfig newConfig
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
                    }
            in
            ( model
            , Cmd.batch
                [ updateCurrentState currentState
                , updateSessionStatus (NotStarted |> sessionStatusToString)
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
                [ updateSessionStatus (NotStarted |> sessionStatusToString)
                , sendMessageFromElm (elmMessageEncoder { name = "reset", value = Nothing })
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
            , updateConfig newConfig
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
            , Cmd.batch [ setVolume newVolume, updateConfig newConfig ]
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
                                        , percentage = toFloat (maxTime - state.currentSession.currentTime) / toFloat maxTime
                                        , paused = True
                                        }
                                in
                                ( { model | currentState = currentState }
                                , Cmd.batch
                                    [ updateCurrentState currentState
                                    , sendMessageFromElm (elmMessageEncoder { name = "pause", value = Nothing })
                                    ]
                                )

                            _ ->
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
                                        , percentage = toFloat (maxTime - state.currentSession.currentTime) / toFloat maxTime
                                        , paused = False
                                        }
                                in
                                ( { model | currentState = currentState }
                                , Cmd.batch
                                    [ updateCurrentState currentState
                                    , sendMessageFromElm (elmMessageEncoder { name = "play", value = Nothing })
                                    ]
                                )
                    )
                |> Maybe.withDefault ( model, Cmd.none )

        UpdateSetting settingType v ->
            let
                value =
                    case String.toInt v of
                        Nothing ->
                            0

                        Just stringValue ->
                            stringValue

                newConfig =
                    case settingType of
                        FocusTime ->
                            { config | focusDuration = min (90 * 60) (value * 60) }

                        LongBreakTime ->
                            { config | longBreakDuration = min (90 * 60) (value * 60) }

                        Rounds ->
                            { config | maxRoundNumber = min 12 value }

                        ShortBreakTime ->
                            { config | shortBreakDuration = min (90 * 60) (value * 60) }
            in
            ( { model | config = newConfig }
            , Cmd.batch
                [ updateConfig newConfig
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
        [ View.navView model
        , if model.drawerOpen then
            View.drawerView model

          else
            View.timerView model
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


port playSound : String -> Cmd msg


port setVolume : Float -> Cmd msg


port closeWindow : () -> Cmd msg


port getConfigFromRust : () -> Cmd msg


port minimizeWindow : () -> Cmd msg


port hideWindow : () -> Cmd msg


port updateCurrentState : CurrentState -> Cmd msg


port updateSessionStatus : String -> Cmd msg


port notify : Notification -> Cmd msg


port updateConfig : Config -> Cmd msg


port setThemeColors : ThemeColors -> Cmd msg
