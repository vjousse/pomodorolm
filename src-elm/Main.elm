port module Main exposing (Flags, Model, Msg, main)

import Browser
import ColorHelper exposing (RGB(..), colorForSessionType, computeCurrentColor, fromCSSHexToRGB, fromRGBToCSSHex)
import Config exposing (Config)
import Html exposing (Html, div)
import Html.Attributes exposing (id)
import Json exposing (ExternalMessage(..), configEncoder, currentStateEncoder, elmMessageBuilder, elmMessageEncoder, externalMessageDecoder, sessionTypeDecoder, soundMessageEncoder)
import Json.Decode as Decode
import Json.Encode as Encode
import Pomodoro
import Seconds exposing (Seconds)
import SessionStatus exposing (SessionStatus(..))
import SessionType exposing (SessionType(..))
import Themes exposing (Theme, pomodorolmTheme)
import TimeHelper exposing (getCurrentMaxTime)
import Types exposing (CurrentState, ResetType(..), Setting(..), SettingTab(..), SettingType(..))
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


type alias Model =
    { appVersion : String
    , config : Config
    , currentColor : RGB
    , currentState : CurrentState
    , drawerOpen : Bool
    , focusLabel : String
    , longBreakLabel : String
    , pomodoroState : Maybe Pomodoro.State
    , settingTab : SettingTab
    , shortBreakLabel : String
    , strokeDasharray : Float
    , theme : Theme
    , themes : List Theme
    , volumeSliderHidden : Bool
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
    , maxSessionDuration : Seconds
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
    , volume : Maybe Int
    }


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
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
            , maxSessionDuration = flags.maxSessionDuration
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
            , volume = flags.volume
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
      , themes = []
      , volumeSliderHidden = True
      }
    , Cmd.batch
        [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
        , sendMessageFromElm (elmMessageEncoder { name = "get_init_data", value = Nothing })
        , setThemeColors (Json.themeColorsEncoder theme.colors)
        ]
    )


type Msg
    = AudioFileRequested SessionType
    | CloseWindow
    | ChangeSettingTab SettingTab
    | ChangeTheme Theme
    | SetVolumeBarVisibility Bool
    | ProcessExternalMessage Decode.Value
    | MinimizeWindow
    | Reset ResetType
    | ResetSettings
    | ResetAudioFile SessionType
    | SkipCurrentRound
    | ToggleDrawer
    | ToggleMute Bool
    | TogglePlayStatus
    | UpdateLabel SessionType String
    | UpdateSetting SettingType
    | UpdateVolume String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config } as model) =
    case msg of
        AudioFileRequested sessionType ->
            ( model
            , sendMessageFromElm
                (elmMessageEncoder
                    { name = "choose_sound_file"
                    , value = Just <| SessionType.toString sessionType
                    }
                )
            )

        ChangeSettingTab settingTab ->
            ( { model | settingTab = settingTab }, Cmd.none )

        ChangeTheme theme ->
            changeTheme theme model

        CloseWindow ->
            ( model
            , if model.config.minimizeToTrayOnClose then
                hideWindow ()

              else
                closeWindow ()
            )

        SetVolumeBarVisibility visible ->
            ( { model | volumeSliderHidden = not visible }, Cmd.none )

        MinimizeWindow ->
            ( model
            , if model.config.minimizeToTray then
                hideWindow ()

              else
                minimizeWindow ()
            )

        ProcessExternalMessage externalMessage ->
            case Decode.decodeValue externalMessageDecoder externalMessage of
                Ok (InitDataMsg c) ->
                    processExternalInitMessage c model

                Ok (RustStateMsg pomodoroState) ->
                    processExternalRustMessage pomodoroState model

                Ok (SoundFilePath sessionType path) ->
                    let
                        ( newConfig, cmd ) =
                            processExternalSoundFilePathMessage sessionType path config
                    in
                    ( { model | config = newConfig }
                    , cmd
                    )

                Err _ ->
                    --@FIX: don't fail silently
                    ( model, Cmd.none )

        Reset resetType ->
            let
                currentState =
                    { color =
                        case model.pomodoroState of
                            Just state ->
                                fromRGBToCSSHex
                                    (colorForSessionType state.currentSession.sessionType model.theme)

                            Nothing ->
                                model.theme.colors.focusRound
                    , percentage = 1
                    , paused =
                        model.pomodoroState |> Maybe.map (\state -> state.currentSession.status == Paused) |> Maybe.withDefault False
                    , sessionStatus = NotStarted
                    }
            in
            ( model
            , Cmd.batch
                [ sendMessageFromElm (elmMessageBuilder "update_current_state" currentState currentStateEncoder)
                , sendMessageFromElm
                    (elmMessageEncoder
                        { name =
                            case resetType of
                                CurrentRound ->
                                    "reset_round"

                                EntireSession ->
                                    "reset_session"
                        , value = Nothing
                        }
                    )
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
            , sendMessageFromElm (elmMessageEncoder { name = "reset", value = Nothing })
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

        ToggleMute muted ->
            let
                newVolume =
                    if muted then
                        Just 0

                    else if (model.config.volume |> Maybe.withDefault 0) > 0 then
                        model.config.volume

                    else
                        Just 100

                newConfig =
                    { config | muted = muted, volume = newVolume }
            in
            ( { model | config = newConfig }
            , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
            )

        TogglePlayStatus ->
            togglePlayStatus model

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
                            { config | autoQuit = SessionType.fromString sessionTypeString }

                        FocusTime value ->
                            { config | focusDuration = min (config.maxSessionDuration * 60) (toInt value * 60) }

                        Label sessionType label ->
                            case sessionType of
                                Focus ->
                                    { config | defaultFocusLabel = label }

                                ShortBreak ->
                                    { config | defaultShortBreakLabel = label }

                                LongBreak ->
                                    { config | defaultLongBreakLabel = label }

                        LongBreakTime value ->
                            { config | longBreakDuration = min (config.maxSessionDuration * 60) (toInt value * 60) }

                        MaxSessionDuration value ->
                            { config | maxSessionDuration = toInt value * 60 }

                        Rounds value ->
                            { config | maxRoundNumber = min 12 (toInt value) }

                        SaveMaxSessionDuration ->
                            { config
                                | focusDuration = min config.focusDuration config.maxSessionDuration
                                , longBreakDuration = min config.longBreakDuration config.maxSessionDuration
                                , shortBreakDuration = min config.shortBreakDuration config.maxSessionDuration
                            }

                        ShortBreakTime value ->
                            { config | shortBreakDuration = min (config.maxSessionDuration * 60) (toInt value * 60) }

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
                            model.config.volume

                        Just v ->
                            Just v

                newConfig =
                    { config | muted = (newVolume |> Maybe.withDefault 0) <= 0, volume = newVolume }
            in
            ( { model | config = newConfig }
            , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
            )


changeTheme : Theme -> Model -> ( Model, Cmd msg )
changeTheme theme ({ config } as model) =
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
        [ setThemeColors (Json.themeColorsEncoder theme.colors)
        , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
        , sendMessageFromElm (elmMessageBuilder "update_current_state" newState currentStateEncoder)
        ]
    )


processExternalInitMessage : Json.InitData -> Model -> ( Model, Cmd Msg )
processExternalInitMessage c model =
    let
        ( newModel, newCmd ) =
            { model
                | config = c.config
                , focusLabel = c.config.defaultFocusLabel
                , longBreakLabel = c.config.defaultLongBreakLabel
                , shortBreakLabel = c.config.defaultShortBreakLabel
                , themes = c.themes
            }
                |> processExternalRustMessage c.pomodoroState

        ( modelWithTheme, cmdWithTheme ) =
            case find (\t -> (t.name |> String.toLower) == c.config.theme) c.themes of
                Just currentTheme ->
                    let
                        ( updatedModel, updatedCmd ) =
                            changeTheme currentTheme newModel
                    in
                    ( updatedModel, Cmd.batch [ updatedCmd, newCmd ] )

                Nothing ->
                    ( newModel, newCmd )
    in
    -- Auto start if config is set
    if modelWithTheme.config.autoStartOnAppStartup then
        let
            ( updatedModel, updatedCmd ) =
                togglePlayStatus modelWithTheme
        in
        ( updatedModel, Cmd.batch [ cmdWithTheme, updatedCmd ] )

    else
        ( modelWithTheme, cmdWithTheme )


processExternalRustMessage : Pomodoro.State -> Model -> ( Model, Cmd Msg )
processExternalRustMessage pomodoroState model =
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
            getCurrentMaxTime model.config pomodoroState.currentSession

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
                                        model.config
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
                                        ((model.config.autoQuit == Just ShortBreak && state.currentSession.sessionType == ShortBreak)
                                            || (model.config.autoQuit == Just LongBreak && state.currentSession.sessionType == LongBreak)
                                        )

                                LongBreak ->
                                    getCmds
                                        model.config
                                        "audio-long-break"
                                        "Focus round completed"
                                        "long break"
                                        "start_long_break"
                                        model.config.longBreakDuration
                                        currentColor
                                        False

                                ShortBreak ->
                                    getCmds
                                        model.config
                                        "audio-short-break"
                                        "Focus round completed"
                                        "short break"
                                        "start_short_break"
                                        model.config.shortBreakDuration
                                        currentColor
                                        (model.config.autoQuit == Just Focus)

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


processExternalSoundFilePathMessage : SessionType -> String -> Config -> ( Config, Cmd msg )
processExternalSoundFilePathMessage sessionType path config =
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
    ( newConfig
    , sendMessageFromElm (elmMessageBuilder "update_config" newConfig configEncoder)
    )


togglePlayStatus : Model -> ( Model, Cmd Msg )
togglePlayStatus model =
    model.pomodoroState
        |> Maybe.map
            (\state ->
                case state.currentSession.status of
                    Running ->
                        let
                            maxTime =
                                getCurrentMaxTime model.config state.currentSession

                            currentState =
                                { color =
                                    fromRGBToCSSHex <|
                                        computeCurrentColor
                                            state.currentSession.currentTime
                                            (getCurrentMaxTime model.config state.currentSession)
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
                                getCurrentMaxTime model.config state.currentSession

                            currentState =
                                { color =
                                    fromRGBToCSSHex <|
                                        computeCurrentColor state.currentSession.currentTime
                                            (getCurrentMaxTime model.config state.currentSession)
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


find : (a -> Bool) -> List a -> Maybe a
find predicate list =
    case list of
        [] ->
            Nothing

        x :: xs ->
            if predicate x then
                Just x

            else
                find predicate xs


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ View.Nav.navView
            { onWindowMinimize = MinimizeWindow
            , onDrawerToggle = ToggleDrawer
            , onWindowClose = CloseWindow
            }
            model.drawerOpen
        , if model.drawerOpen then
            View.Drawer.view
                { onSettingUpdate = UpdateSetting
                , onSettingsReset = ResetSettings
                , onChangeSettingTab = ChangeSettingTab
                , onAudioFileReset = ResetAudioFile
                , onAudioFileRequested = AudioFileRequested
                , onThemeChange = ChangeTheme
                }
                model

          else
            View.Timer.view
                { onReset = Reset
                , onCurrentRoundSkip = SkipCurrentRound
                , onSetVolumeBarVisibility = SetVolumeBarVisibility
                , onVolumeUpdate = UpdateVolume
                , onToggleMute = ToggleMute
                , onUpdateLabel = UpdateLabel
                , onTogglePlayStatus = TogglePlayStatus
                }
                model
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ togglePlay (always TogglePlayStatus)
        , skip (always SkipCurrentRound)
        , sendMessageToElm ProcessExternalMessage
        ]


port togglePlay : (() -> msg) -> Sub msg


port skip : (() -> msg) -> Sub msg


port sendMessageToElm : (Decode.Value -> msg) -> Sub msg



-- PORTS


port sendMessageFromElm : Encode.Value -> Cmd msg


port closeWindow : () -> Cmd msg


port minimizeWindow : () -> Cmd msg


port hideWindow : () -> Cmd msg


type alias Notification =
    { body : String
    , title : String
    , name : String
    , red : Int
    , green : Int
    , blue : Int
    }


port notify : Notification -> Cmd msg


port setThemeColors : Encode.Value -> Cmd msg
