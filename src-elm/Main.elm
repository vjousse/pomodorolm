port module Main exposing (..)

import Browser
import ColorHelper exposing (RGB(..), fromCSSHexToRGB, fromRGBToCSSHex)
import Html exposing (Html, a, div, h1, h2, input, nav, p, section, text)
import Html.Attributes exposing (attribute, class, href, id, style, target, title, type_, value)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipe
import Json.Encode
import ListWithCurrent exposing (ListWithCurrent(..))
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Themes exposing (Theme, ThemeColors, pomodorolmTheme)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Seconds =
    Int


type alias Model =
    { appVersion : String
    , config : Config
    , currentColor : RGB
    , currentRoundNumber : Int
    , currentSessionType : SessionType
    , currentState : CurrentState
    , currentTime : Seconds
    , drawerOpen : Bool
    , muted : Bool
    , sessionStatus : SessionStatus
    , settingTab : SettingTab
    , strokeDasharray : Float
    , theme : Theme
    , themes : ListWithCurrent Theme
    , volume : Float
    , volumeSliderHidden : Bool
    }


type alias Config =
    { alwaysOnTop : Bool
    , autoStartBreakTimer : Bool
    , autoStartWorkTimer : Bool
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , theme : String
    , tickSoundsDuringBreak : Bool
    , tickSoundsDuringWork : Bool
    }


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
    Decode.map6 (<|)
        fieldSet0
        (Decode.field "pomodoro_duration" Decode.int)
        (Decode.field "short_break_duration" Decode.int)
        (Decode.field "theme" Decode.string)
        (Decode.field "tick_sounds_during_break" Decode.bool)
        (Decode.field "tick_sounds_during_work" Decode.bool)


encodedConfig : Config -> Json.Encode.Value
encodedConfig config =
    Json.Encode.object
        [ ( "always_on_top", Json.Encode.bool config.alwaysOnTop )
        , ( "auto_start_break_timer", Json.Encode.bool config.autoStartBreakTimer )
        , ( "auto_start_work_timer", Json.Encode.bool config.autoStartWorkTimer )
        , ( "desktop_notifications", Json.Encode.bool config.desktopNotifications )
        , ( "long_break_duration", Json.Encode.int config.longBreakDuration )
        , ( "max_round_number", Json.Encode.int config.maxRoundNumber )
        , ( "minimize_to_tray", Json.Encode.bool config.minimizeToTray )
        , ( "minimize_to_tray_on_close", Json.Encode.bool config.minimizeToTrayOnClose )
        , ( "pomodoro_duration", Json.Encode.int config.pomodoroDuration )
        , ( "short_break_duration", Json.Encode.int config.shortBreakDuration )
        , ( "tick_sounds_during_break", Json.Encode.bool config.tickSoundsDuringBreak )
        , ( "tick_sounds_during_work", Json.Encode.bool config.tickSoundsDuringWork )
        ]


type alias CurrentState =
    { color : String, percentage : Float, paused : Bool, playTick : Bool }


type SessionType
    = Pomodoro
    | ShortBreak
    | LongBreak


type SessionStatus
    = Paused
    | Stopped
    | Running


type SettingTab
    = TimerTab
    | ThemeTab
    | SettingsTab
    | AboutTab


type Setting
    = AlwaysOnTop
    | AutoStartWorkTimer
    | AutoStartBreakTimer
    | TickSoundsDuringWork
    | TickSoundsDuringBreak
    | DesktopNotifications
    | MinimizeToTray
    | MinimizeToTrayOnClose


type alias Notification =
    { body : String
    , title : String
    , name : String
    , red : Int
    , green : Int
    , blue : Int
    }


type alias NextRoundInfo =
    { nextSessionType : SessionType
    , htmlIdOfAudioToPlay : String
    , nextRoundNumber : Int
    , nextTime : Seconds
    , notification : Notification
    }


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
    }


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
    , pomodoroDuration : Seconds
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
            , playTick = False
            }
    in
    ( { appVersion = flags.appVersion
      , config =
            { alwaysOnTop = flags.alwaysOnTop
            , autoStartWorkTimer = flags.autoStartWorkTimer
            , autoStartBreakTimer = flags.autoStartBreakTimer
            , desktopNotifications = flags.desktopNotifications
            , longBreakDuration = flags.longBreakDuration
            , maxRoundNumber = flags.maxRoundNumber
            , minimizeToTray = flags.minimizeToTray
            , minimizeToTrayOnClose = flags.minimizeToTrayOnClose
            , pomodoroDuration = flags.pomodoroDuration
            , shortBreakDuration = flags.shortBreakDuration
            , theme = flags.theme
            , tickSoundsDuringWork = flags.tickSoundsDuringWork
            , tickSoundsDuringBreak = flags.tickSoundsDuringBreak
            }
      , currentColor = fromCSSHexToRGB theme.colors.focusRound
      , currentRoundNumber = 1
      , currentSessionType = Pomodoro
      , currentState = currentState
      , currentTime = flags.pomodoroDuration
      , drawerOpen = False
      , muted = False
      , sessionStatus = Stopped
      , settingTab = TimerTab
      , strokeDasharray = 691.3321533203125
      , theme = theme
      , themes = ListWithCurrent.fromList [ theme ]
      , volume = 1
      , volumeSliderHidden = True
      }
    , Cmd.batch
        [ updateCurrentState currentState
        , loadRustConfig ()
        , setThemeColors <| theme.colors
        ]
    )


type SettingType
    = FocusTime
    | LongBreakTime
    | Rounds
    | ShortBreakTime


type Msg
    = CloseWindow
    | ChangeSettingTab SettingTab
    | ChangeSettingConfig Setting
    | ChangeTheme Theme
    | HideVolumeBar
    | LoadConfig Config
    | LoadThemes (List Theme)
    | MinimizeWindow
    | NoOp
    | Reset
    | ResetSettings
    | SkipCurrentRound
    | ShowVolumeBar
    | Tick String
    | ToggleDrawer
    | ToggleMute
    | ToggleStatus
    | UpdateSetting SettingType String
    | UpdateVolume String


getNextRoundInfo : Model -> NextRoundInfo
getNextRoundInfo model =
    let
        getNotification : String -> String -> String -> Seconds -> SessionType -> Notification
        getNotification title body name duration sessionType =
            let
                ( r, g, b ) =
                    case computeCurrentColor 1 1 sessionType model.theme of
                        RGB red_ green_ blue_ ->
                            ( red_, green_, blue_ )

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
    in
    case model.currentSessionType of
        Pomodoro ->
            if model.currentRoundNumber == model.config.maxRoundNumber then
                { nextSessionType = LongBreak
                , htmlIdOfAudioToPlay = "audio-long-break"
                , nextRoundNumber = model.currentRoundNumber
                , nextTime = model.config.longBreakDuration
                , notification = getNotification "Focus round completed" "long break" "start_long_break" model.config.longBreakDuration LongBreak
                }

            else
                { nextSessionType = ShortBreak
                , htmlIdOfAudioToPlay = "audio-short-break"
                , nextRoundNumber = model.currentRoundNumber
                , nextTime = model.config.shortBreakDuration
                , notification = getNotification "Focus round completed" "short break" "start_short_break" model.config.shortBreakDuration ShortBreak
                }

        ShortBreak ->
            { nextSessionType = Pomodoro
            , htmlIdOfAudioToPlay = "audio-work"
            , nextRoundNumber = model.currentRoundNumber + 1
            , nextTime = model.config.pomodoroDuration
            , notification = getNotification "Short break completed" "focus round" "start_focus" model.config.shortBreakDuration Pomodoro
            }

        LongBreak ->
            { nextSessionType = Pomodoro
            , htmlIdOfAudioToPlay = "audio-work"
            , nextRoundNumber = 1
            , nextTime = model.config.pomodoroDuration
            , notification = getNotification "Long break completed" "focus round" "start_focus" model.config.shortBreakDuration Pomodoro
            }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "MSG" msg of
        ChangeSettingConfig settingConfig ->
            let
                settingsConfig =
                    model.config

                newSettingsConfig =
                    case settingConfig of
                        AlwaysOnTop ->
                            { settingsConfig | alwaysOnTop = not settingsConfig.alwaysOnTop }

                        AutoStartBreakTimer ->
                            { settingsConfig | autoStartBreakTimer = not settingsConfig.autoStartBreakTimer }

                        AutoStartWorkTimer ->
                            { settingsConfig | autoStartWorkTimer = not settingsConfig.autoStartWorkTimer }

                        TickSoundsDuringWork ->
                            { settingsConfig | tickSoundsDuringWork = not settingsConfig.tickSoundsDuringWork }

                        TickSoundsDuringBreak ->
                            { settingsConfig | tickSoundsDuringBreak = not settingsConfig.tickSoundsDuringBreak }

                        DesktopNotifications ->
                            { settingsConfig | desktopNotifications = not settingsConfig.desktopNotifications }

                        MinimizeToTray ->
                            { settingsConfig | minimizeToTray = not settingsConfig.minimizeToTray }

                        MinimizeToTrayOnClose ->
                            { settingsConfig | minimizeToTrayOnClose = not settingsConfig.minimizeToTrayOnClose }

                nextModel =
                    { model | config = newSettingsConfig }

                oldState =
                    nextModel.currentState

                currentState =
                    { oldState | playTick = shouldPlayTick model }
            in
            ( { nextModel | currentState = currentState }, Cmd.batch [ updateConfig newSettingsConfig, updateCurrentState currentState ] )

        ChangeSettingTab settingTab ->
            ( { model | settingTab = settingTab }, Cmd.none )

        ChangeTheme theme ->
            let
                currentState =
                    model.currentState

                newState =
                    { currentState | color = fromRGBToCSSHex <| colorForSessionType model.currentSessionType theme }

                config =
                    model.config

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

        LoadConfig config ->
            let
                updatedThemes =
                    model.themes
                        |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == config.theme)

                newThemes =
                    case ListWithCurrent.getCurrent updatedThemes of
                        Just theme ->
                            -- We found a theme with the same name than in the config: everything's fine
                            if (theme.name |> String.toLower) == (model.config.theme |> String.toLower) then
                                updatedThemes

                            else
                                -- If we didn't found a corresponding theme name, pomodorolm should be the default theme
                                updatedThemes |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == "pomodorolm")

                        Nothing ->
                            updatedThemes

                newModel =
                    { model
                        | config = config
                        , sessionStatus = Stopped
                        , themes = newThemes
                        , currentTime =
                            case model.currentSessionType of
                                Pomodoro ->
                                    config.pomodoroDuration

                                ShortBreak ->
                                    config.shortBreakDuration

                                LongBreak ->
                                    config.longBreakDuration
                    }
            in
            case newThemes |> ListWithCurrent.getCurrent of
                Just currentTheme ->
                    update (ChangeTheme currentTheme) newModel

                _ ->
                    ( newModel, Cmd.none )

        LoadThemes themes ->
            let
                loadedThemes =
                    themes
                        |> List.sortBy .name
                        |> ListWithCurrent.fromList
                        |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == model.config.theme)

                newThemes =
                    case Debug.log "Current" (ListWithCurrent.getCurrent loadedThemes) of
                        Just theme ->
                            -- We found a theme with the same name than in the config: everything's fine
                            if (theme.name |> String.toLower) == (model.config.theme |> String.toLower) then
                                loadedThemes

                            else
                                -- If we didn't found a corresponding theme name, pomodorolm should be the default theme
                                loadedThemes |> ListWithCurrent.setCurrentByPredicate (\t -> (t.name |> String.toLower) == "pomodorolm")

                        Nothing ->
                            loadedThemes

                newModel =
                    { model
                        | themes = newThemes
                    }
            in
            case newThemes |> ListWithCurrent.getCurrent of
                Just currentTheme ->
                    update (ChangeTheme currentTheme) newModel

                _ ->
                    ( newModel, Cmd.none )

        MinimizeWindow ->
            ( model
            , if model.config.minimizeToTray then
                hideWindow ()

              else
                minimizeWindow ()
            )

        NoOp ->
            ( model, Cmd.none )

        Reset ->
            let
                currentState =
                    { color = fromRGBToCSSHex <| colorForSessionType model.currentSessionType model.theme
                    , percentage = 100
                    , paused =
                        if model.sessionStatus == Paused then
                            True

                        else
                            False
                    , playTick = False
                    }
            in
            ( { model
                | sessionStatus = Stopped
                , currentTime =
                    case model.currentSessionType of
                        Pomodoro ->
                            model.config.pomodoroDuration

                        ShortBreak ->
                            model.config.shortBreakDuration

                        LongBreak ->
                            model.config.longBreakDuration
              }
            , updateCurrentState currentState
            )

        ResetSettings ->
            let
                config =
                    model.config

                newConfig =
                    { config
                        | pomodoroDuration = defaults.pomodoroDuration
                        , shortBreakDuration = defaults.shortBreakDuration
                        , longBreakDuration = defaults.longBreakDuration
                        , maxRoundNumber = defaults.maxRoundNumber
                    }

                oldState =
                    model.currentState

                currentState =
                    { oldState | playTick = False }
            in
            ( { model
                | config = newConfig
                , currentTime = defaults.pomodoroDuration
                , currentSessionType = Pomodoro
                , currentState = currentState
                , sessionStatus = Stopped
              }
            , updateCurrentState currentState
            )

        SkipCurrentRound ->
            let
                nextRoundInfo =
                    getNextRoundInfo model

                nextModel =
                    { model
                        | currentRoundNumber = nextRoundInfo.nextRoundNumber
                        , currentSessionType = nextRoundInfo.nextSessionType
                        , currentTime = nextRoundInfo.nextTime
                        , sessionStatus =
                            case nextRoundInfo.nextSessionType of
                                Pomodoro ->
                                    if model.config.autoStartWorkTimer then
                                        Running

                                    else
                                        Stopped

                                _ ->
                                    if model.config.autoStartBreakTimer then
                                        Running

                                    else
                                        Stopped
                    }

                currentState =
                    { color = fromRGBToCSSHex <| colorForSessionType nextRoundInfo.nextSessionType model.theme
                    , percentage = 100
                    , paused =
                        if model.sessionStatus == Paused then
                            True

                        else
                            False
                    , playTick = shouldPlayTick nextModel
                    }
            in
            ( { nextModel | currentState = currentState }
            , Cmd.batch
                [ if model.muted then
                    Cmd.none

                  else
                    playSound nextRoundInfo.htmlIdOfAudioToPlay
                , updateCurrentState currentState
                , if model.config.desktopNotifications then
                    notify nextRoundInfo.notification

                  else
                    Cmd.none
                ]
            )

        ShowVolumeBar ->
            ( { model | volumeSliderHidden = False }, Cmd.none )

        Tick _ ->
            if model.currentTime > 0 && model.sessionStatus == Running then
                let
                    newTime =
                        model.currentTime - 1

                    maxTime =
                        getCurrentMaxTime model

                    currentColor =
                        computeCurrentColor newTime maxTime model.currentSessionType model.theme

                    percent =
                        1 * toFloat newTime / toFloat maxTime

                    nextModel =
                        { model
                            | currentTime = newTime
                            , currentColor = currentColor
                        }

                    currentState =
                        { color = fromRGBToCSSHex currentColor
                        , percentage = percent
                        , paused =
                            if model.sessionStatus == Paused then
                                True

                            else
                                False
                        , playTick = shouldPlayTick nextModel
                        }
                in
                ( { model
                    | currentTime = newTime
                    , currentColor = currentColor
                    , currentState = currentState
                  }
                , updateCurrentState currentState
                )

            else if model.currentTime == 0 then
                -- Time = 0, we are at the end of the current round
                let
                    nextRoundInfo =
                        getNextRoundInfo model

                    nextModel =
                        { model
                            | currentRoundNumber = nextRoundInfo.nextRoundNumber
                            , currentSessionType = nextRoundInfo.nextSessionType
                            , currentTime = nextRoundInfo.nextTime
                            , sessionStatus =
                                case nextRoundInfo.nextSessionType of
                                    Pomodoro ->
                                        if model.config.autoStartWorkTimer then
                                            Running

                                        else
                                            Stopped

                                    _ ->
                                        if model.config.autoStartBreakTimer then
                                            Running

                                        else
                                            Stopped
                        }

                    currentState =
                        { color = fromRGBToCSSHex <| colorForSessionType nextRoundInfo.nextSessionType model.theme
                        , percentage = 100
                        , paused =
                            if nextModel.sessionStatus == Paused then
                                True

                            else
                                False
                        , playTick = shouldPlayTick nextModel
                        }
                in
                ( { nextModel
                    | currentRoundNumber = nextRoundInfo.nextRoundNumber
                    , currentSessionType = nextRoundInfo.nextSessionType
                    , currentTime = nextRoundInfo.nextTime
                    , currentState = currentState
                    , sessionStatus =
                        case nextRoundInfo.nextSessionType of
                            Pomodoro ->
                                if model.config.autoStartWorkTimer then
                                    Running

                                else
                                    Stopped

                            _ ->
                                if model.config.autoStartBreakTimer then
                                    Running

                                else
                                    Stopped
                  }
                , Cmd.batch
                    [ updateCurrentState currentState
                    , if nextModel.muted then
                        Cmd.none

                      else
                        playSound nextRoundInfo.htmlIdOfAudioToPlay
                    , if model.config.desktopNotifications then
                        notify nextRoundInfo.notification

                      else
                        Cmd.none
                    ]
                )

            else
                ( model, Cmd.none )

        ToggleDrawer ->
            let
                config =
                    model.config

                newConfig =
                    { config
                        | -- Avoid having impossible states
                          maxRoundNumber =
                            if model.config.maxRoundNumber == 0 then
                                1

                            else
                                model.config.maxRoundNumber
                        , pomodoroDuration =
                            if model.config.pomodoroDuration == 0 then
                                60

                            else
                                model.config.pomodoroDuration
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
                    if model.muted then
                        model.volume

                    else
                        0

                nextModel =
                    { model | muted = not model.muted, volume = newVolume }

                oldState =
                    model.currentState

                currentState =
                    { oldState
                        | playTick = shouldPlayTick nextModel
                    }
            in
            ( { nextModel | currentState = currentState }
            , Cmd.batch [ setVolume newVolume, updateCurrentState currentState ]
            )

        ToggleStatus ->
            case model.sessionStatus of
                Running ->
                    let
                        nextModel =
                            { model | sessionStatus = Paused }

                        currentState =
                            { color =
                                fromRGBToCSSHex <|
                                    computeCurrentColor
                                        model.currentTime
                                        (getCurrentMaxTime model)
                                        model.currentSessionType
                                        model.theme
                            , percentage = 1 * toFloat model.currentTime / toFloat (getCurrentMaxTime model)
                            , paused = True
                            , playTick = shouldPlayTick nextModel
                            }
                    in
                    ( { nextModel | currentState = currentState }
                    , updateCurrentState currentState
                    )

                _ ->
                    let
                        nextModel =
                            { model | sessionStatus = Running }

                        currentState =
                            { color =
                                fromRGBToCSSHex <|
                                    computeCurrentColor model.currentTime
                                        (getCurrentMaxTime model)
                                        model.currentSessionType
                                        model.theme
                            , percentage = 1 * toFloat model.currentTime / toFloat (getCurrentMaxTime model)
                            , paused = False
                            , playTick = shouldPlayTick nextModel
                            }
                    in
                    ( { nextModel | currentState = currentState }
                    , updateCurrentState currentState
                    )

        UpdateSetting settingType v ->
            let
                value =
                    case String.toInt v of
                        Nothing ->
                            0

                        Just stringValue ->
                            stringValue

                config =
                    model.config
            in
            case settingType of
                FocusTime ->
                    let
                        newValue =
                            if value > 90 then
                                90 * 60

                            else
                                value * 60

                        newConfig =
                            { config | pomodoroDuration = newValue }
                    in
                    ( { model
                        | config = newConfig
                        , currentTime =
                            if model.currentSessionType == Pomodoro then
                                if newValue == 0 then
                                    60

                                else
                                    newValue

                            else
                                model.currentTime
                      }
                    , updateConfig newConfig
                    )

                LongBreakTime ->
                    let
                        newValue =
                            if value > 90 then
                                90 * 60

                            else
                                value * 60
                    in
                    ( { model
                        | config = { config | longBreakDuration = newValue }
                        , currentTime =
                            if model.currentSessionType == LongBreak then
                                if newValue == 0 then
                                    60

                                else
                                    newValue

                            else
                                model.currentTime
                      }
                    , Cmd.none
                    )

                Rounds ->
                    let
                        newValue =
                            if value > 12 then
                                12

                            else
                                value
                    in
                    ( { model
                        | config = { config | maxRoundNumber = newValue }
                      }
                    , Cmd.none
                    )

                ShortBreakTime ->
                    let
                        newValue =
                            if value > 90 then
                                90 * 60

                            else
                                value * 60
                    in
                    ( { model
                        | config = { config | shortBreakDuration = newValue }
                        , currentTime =
                            if model.currentSessionType == ShortBreak then
                                if newValue == 0 then
                                    60

                                else
                                    newValue

                            else
                                model.currentTime
                      }
                    , Cmd.none
                    )

        UpdateVolume volumeStr ->
            let
                newVolume =
                    case String.toInt volumeStr of
                        Nothing ->
                            model.volume

                        Just v ->
                            toFloat v / 100
            in
            ( { model
                | volume = newVolume
                , muted =
                    if newVolume > 0 then
                        False

                    else
                        True
              }
            , setVolume newVolume
            )


shouldPlayTick : Model -> Bool
shouldPlayTick model =
    -- If it's muted, don't play anything
    if model.muted then
        False

    else if model.currentTime > 0 && model.sessionStatus == Running then
        case ( model.currentSessionType, model.config.tickSoundsDuringWork, model.config.tickSoundsDuringBreak ) of
            ( Pomodoro, True, _ ) ->
                True

            ( ShortBreak, _, True ) ->
                True

            ( LongBreak, _, True ) ->
                True

            _ ->
                False

    else
        False


colorForSessionType : SessionType -> Theme -> RGB
colorForSessionType sessionType theme =
    case sessionType of
        Pomodoro ->
            fromCSSHexToRGB <| theme.colors.focusRound

        ShortBreak ->
            fromCSSHexToRGB <| theme.colors.shortRound

        LongBreak ->
            fromCSSHexToRGB <| theme.colors.longRound


computeCurrentColor : Seconds -> Seconds -> SessionType -> Theme -> RGB
computeCurrentColor currentTime maxTime sessionType theme =
    let
        percent =
            1 * toFloat currentTime / toFloat maxTime

        relativePercent =
            1 * (toFloat currentTime - toFloat maxTime / 2) / (toFloat maxTime / 2)
    in
    case sessionType of
        Pomodoro ->
            let
                ( startRed, startGreen, startBlue ) =
                    case fromCSSHexToRGB theme.colors.focusRound of
                        RGB r g b ->
                            ( r, g, b )

                ( middleRed, middleGreen, middleBlue ) =
                    case fromCSSHexToRGB theme.colors.focusRoundMiddle of
                        RGB r g b ->
                            ( r, g, b )

                ( endRed, endGreen, endBlue ) =
                    case fromCSSHexToRGB theme.colors.focusRoundEnd of
                        RGB r g b ->
                            ( r, g, b )
            in
            if percent > 0.5 then
                RGB
                    (toFloat middleRed + (relativePercent * toFloat (startRed - middleRed)) |> round)
                    (toFloat middleGreen + (relativePercent * toFloat (startGreen - middleGreen)) |> round)
                    (toFloat middleBlue + (relativePercent * toFloat (startBlue - middleBlue)) |> round)

            else
                RGB (toFloat endRed + ((1 + relativePercent) * toFloat (middleRed - endRed)) |> round)
                    (toFloat endGreen + ((1 + relativePercent) * toFloat (middleGreen - endGreen)) |> round)
                    (toFloat endBlue + ((1 + relativePercent) * toFloat (middleBlue - endBlue)) |> round)

        s ->
            colorForSessionType s theme


secondsToString : Seconds -> String
secondsToString seconds =
    (String.padLeft 2 '0' <| String.fromInt (seconds // 60)) ++ ":" ++ (String.padLeft 2 '0' <| String.fromInt (modBy 60 seconds))


dialView : SessionType -> Seconds -> Seconds -> Float -> Theme -> Html Msg
dialView sessionType currentTime maxTime maxStrokeDasharray theme =
    let
        percent =
            1 * toFloat currentTime / toFloat maxTime

        strokeDasharray =
            maxStrokeDasharray - maxStrokeDasharray * percent

        colorToHtmlRgbString (RGB r g b) =
            "rgb(" ++ String.fromInt r ++ ", " ++ String.fromInt g ++ ", " ++ String.fromInt b ++ ")"

        color =
            colorToHtmlRgbString <| computeCurrentColor currentTime maxTime sessionType theme
    in
    div [ class "dial-wrapper" ]
        [ p [ class "dial-time" ]
            [ text <| secondsToString currentTime ]
        , p [ class "dial-label", style "color" color ]
            [ text <|
                case sessionType of
                    Pomodoro ->
                        "Focus"

                    ShortBreak ->
                        "Short break"

                    LongBreak ->
                        "Long break"
            ]
        , svg
            [ SvgAttr.version "1.2"
            , SvgAttr.baseProfile "tiny"
            , SvgAttr.id "Layer_1"
            , SvgAttr.x "0px"
            , SvgAttr.y "0px"
            , SvgAttr.viewBox "0 0 230 230"
            , SvgAttr.xmlSpace "preserve"
            , SvgAttr.width "60vw"
            , SvgAttr.height "60vw"
            , SvgAttr.class "dial-fill"
            , SvgAttr.style <| "stroke: " ++ color ++ ";"
            ]
            [ path
                [ SvgAttr.fill "none"
                , SvgAttr.strokeWidth "10"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeMiterlimit "10"
                , SvgAttr.d "M115,5c60.8,0,110,49.2,110,110s-49.2,110-110,110S5,175.8,5,115S54.2,5,115,5"
                , SvgAttr.strokeDasharray <| String.fromFloat maxStrokeDasharray
                , SvgAttr.style <| "stroke-dashoffset: " ++ String.fromFloat strokeDasharray ++ "px;"
                ]
                []
            ]
        , svg
            [ SvgAttr.version "1.2"
            , SvgAttr.baseProfile "tiny"
            , SvgAttr.id "Layer_1"
            , SvgAttr.x "0px"
            , SvgAttr.y "0px"
            , SvgAttr.viewBox "0 0 230 230"
            , SvgAttr.xmlSpace "preserve"
            , SvgAttr.width "60vw"
            , SvgAttr.height "60vw"
            , SvgAttr.class "dial-bg"
            ]
            [ path
                [ SvgAttr.fill "none"
                , SvgAttr.strokeWidth "2"
                , SvgAttr.strokeLinecap "round"
                , SvgAttr.strokeMiterlimit "10"
                , SvgAttr.d "M115,5c60.8,0,110,49.2,110,110s-49.2,110-110,110S5,175.8,5,115S54.2,5,115,5"
                ]
                []
            ]
        ]


playPauseView : SessionStatus -> Html Msg
playPauseView sessionStatus =
    let
        pauseSvg =
            svg
                [ SvgAttr.version "1.2"
                , SvgAttr.baseProfile "tiny"
                , SvgAttr.id "Layer_2"
                , SvgAttr.x "0px"
                , SvgAttr.y "0px"
                , SvgAttr.viewBox "0 0 10.9 18"
                , SvgAttr.xmlSpace "preserve"
                , SvgAttr.height "4vw"
                , SvgAttr.class "icon--pause"
                ]
                [ Svg.line
                    [ SvgAttr.fill "none"
                    , SvgAttr.stroke "var(--color-foreground)"
                    , SvgAttr.strokeWidth "3"
                    , SvgAttr.strokeLinecap "round"
                    , SvgAttr.strokeMiterlimit "10"
                    , SvgAttr.x1 "1.5"
                    , SvgAttr.y1 "1.5"
                    , SvgAttr.x2 "1.5"
                    , SvgAttr.y2 "16.5"
                    ]
                    []
                , Svg.line
                    [ SvgAttr.fill "none"
                    , SvgAttr.stroke "var(--color-foreground)"
                    , SvgAttr.strokeWidth "3"
                    , SvgAttr.strokeLinecap "round"
                    , SvgAttr.strokeMiterlimit "10"
                    , SvgAttr.x1 "9.4"
                    , SvgAttr.y1 "1.5"
                    , SvgAttr.x2 "9.4"
                    , SvgAttr.y2 "16.5"
                    ]
                    []
                ]

        playSvg =
            svg
                [ SvgAttr.version "1.2"
                , SvgAttr.baseProfile "tiny"
                , SvgAttr.id "Layer_1"
                , SvgAttr.x "0px"
                , SvgAttr.y "0px"
                , SvgAttr.viewBox "0 0 7.6 15"
                , SvgAttr.xmlSpace "preserve"
                , SvgAttr.height "4vw"
                , SvgAttr.class "icon--start"
                ]
                [ Svg.polygon
                    [ SvgAttr.fill "var(--color-foreground)"
                    , SvgAttr.points "0,0 0,15 7.6,7.4 "
                    ]
                    []
                ]
    in
    section [ class "container", class "button-wrapper" ]
        [ div [ class "button", onClick ToggleStatus ]
            [ div [ class "button-icon-wrapper" ]
                [ case sessionStatus of
                    Running ->
                        pauseSvg

                    _ ->
                        playSvg
                ]
            ]
        ]


footerView : Model -> Html Msg
footerView model =
    section [ class "container", class "footer" ]
        [ div [ class "round-wrapper" ]
            [ p [] [ text <| String.fromInt model.currentRoundNumber ++ "/" ++ String.fromInt model.config.maxRoundNumber ]
            , p [ class "text-button", title "Reset current round", onClick Reset ] [ text "Reset" ]
            ]
        , div [ class "icon-group", style "position" "absolute", style "right" "0px" ]
            [ div [ class "icon-wrapper", class "icon-wrapper--double--left", title "Skip the current round", onClick SkipCurrentRound ]
                [ svg
                    [ SvgAttr.version "1.2"
                    , SvgAttr.baseProfile "tiny"
                    , SvgAttr.id "Layer_1"
                    , SvgAttr.x "0px"
                    , SvgAttr.y "0px"
                    , SvgAttr.viewBox "0 0 8 12"
                    , SvgAttr.xmlSpace "preserve"
                    , SvgAttr.height "5vw"
                    , SvgAttr.class "icon--skip"
                    ]
                    [ Svg.polygon
                        [ SvgAttr.fill "var(--color-background-lightest)"
                        , SvgAttr.points "0,0 0,12 6.1,5.9"
                        ]
                        []
                    , Svg.rect
                        [ SvgAttr.x "6.9"
                        , SvgAttr.y "0"
                        , SvgAttr.fill "var(--color-background-lightest)"
                        , SvgAttr.width "1.1"
                        , SvgAttr.height "12"
                        ]
                        []
                    ]
                ]
            , div [ class "icon-wrapper", class "icon-wrapper--double--right", id "toggle-mute", onClick ToggleMute, title "Mute" ]
                [ if model.muted == False then
                    svg
                        [ SvgAttr.version "1.2"
                        , SvgAttr.id "Layer_1"
                        , SvgAttr.x "0px"
                        , SvgAttr.y "0px"
                        , SvgAttr.viewBox "0 0 12.3 12"
                        , SvgAttr.xmlSpace "preserve"
                        , SvgAttr.height "4vw"
                        , SvgAttr.class "icon--mute"
                        , SvgAttr.baseProfile "tiny"
                        ]
                        [ path
                            [ SvgAttr.fill "var(--color-background-lightest)"
                            , SvgAttr.d "M0,3.9v4.1h2.7l3.4,3.4V0.5L2.7,3.9H0z M9.2,6c0-1.2-0.7-2.3-1.7-2.8v5.5C8.5,8.3,9.2,7.2,9.2,6z M7.5,0v1.4 c2,0.6,3.4,2.4,3.4,4.6s-1.4,4-3.4,4.6V12c2.7-0.6,4.8-3.1,4.8-6S10.3,0.6,7.5,0z"
                            ]
                            []
                        ]

                  else
                    svg
                        [ SvgAttr.version "1.1"
                        , SvgAttr.id "Layer_1"
                        , SvgAttr.x "0px"
                        , SvgAttr.y "0px"
                        , SvgAttr.viewBox "-467 269 24 24"
                        , SvgAttr.xmlSpace "preserve"
                        , SvgAttr.height "5vw"
                        , SvgAttr.class "icon--muted"
                        ]
                        [ path
                            [ SvgAttr.fill "var(--color-background-lightest)"
                            , SvgAttr.d "M-450.5,281c0-1.8-1-3.3-2.5-4v2.2l2.5,2.5C-450.5,281.4-450.5,281.2-450.5,281z M-448,281c0,0.9-0.2,1.8-0.5,2.6l1.5,1.5\n            c0.7-1.2,1-2.6,1-4.1c0-4.3-3-7.9-7-8.8v2.1C-450.1,275.1-448,277.8-448,281z M-462.7,272l-1.3,1.3l4.7,4.7h-4.7v6h4l5,5v-6.7\n            l4.3,4.3c-0.7,0.5-1.4,0.9-2.3,1.2v2.1c1.4-0.3,2.6-1,3.7-1.8l2,2l1.3-1.3l-9-9L-462.7,272z M-455,273l-2.1,2.1l2.1,2.1V273z"
                            ]
                            []
                        , path
                            [ SvgAttr.fill "none"
                            , SvgAttr.d "M-467,269h24v24h-24V269z"
                            ]
                            []
                        ]
                ]
            , div
                [ class "slider-wrapper"
                , class "slider-wrapper--vert"
                , id "volume-slider"
                , style "display"
                    (if model.volumeSliderHidden then
                        "none"

                     else
                        "block"
                    )
                , onMouseLeave HideVolumeBar
                ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "0"
                    , Html.Attributes.max "100"
                    , class "slider"
                    , onInput UpdateVolume
                    , value (model.volume * 100 |> String.fromFloat)
                    ]
                    []
                , div [ class "slider-bar", class "slider-bar--blue-grey" ] []
                ]
            ]
        ]


getCurrentMaxTime : Model -> Seconds
getCurrentMaxTime model =
    case model.currentSessionType of
        Pomodoro ->
            model.config.pomodoroDuration

        LongBreak ->
            model.config.longBreakDuration

        ShortBreak ->
            model.config.shortBreakDuration


timerView : Model -> Html Msg
timerView model =
    div [ class "timer-wrapper" ]
        [ dialView model.currentSessionType model.currentTime (getCurrentMaxTime model) model.strokeDasharray model.theme
        , playPauseView model.sessionStatus
        , footerView model
        ]


navView : Model -> Html Msg
navView model =
    nav [ class "titlebar" ]
        [ div [ title "Settings", class "icon-wrapper", class "icon-wrapper--titlebar", class "icon-wrapper--single", onClick ToggleDrawer ]
            [ div
                [ class "menu-wrapper"
                , class
                    (if model.drawerOpen then
                        "is-collapsed"

                     else
                        ""
                    )
                ]
                [ div [ class "menu-line" ] []
                , div [ class "menu-line" ] []
                ]
            ]
        , h1 [ class "title", attribute "data-tauri-drag-region" "" ] [ text "Pomodorolm" ]
        , div [ class "icon-group" ]
            [ div [ class "icon-wrapper icon-wrapper--titlebar icon-wrapper--double--left", style "padding-left" "5vw", onClick MinimizeWindow ]
                [ svg
                    [ SvgAttr.version "1.2"
                    , SvgAttr.baseProfile "tiny"
                    , SvgAttr.id "Layer_1"
                    , SvgAttr.x "0px"
                    , SvgAttr.y "0px"
                    , SvgAttr.viewBox "0 0 14 2"
                    , SvgAttr.xmlSpace "preserve"
                    , SvgAttr.width "4.2vw"
                    , SvgAttr.height "5.5vw"
                    , SvgAttr.class "icon icon--minimize"
                    ]
                    [ Svg.line
                        [ SvgAttr.fill "none"
                        , SvgAttr.stroke "#F6F2EB"
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.strokeLinecap "round"
                        , SvgAttr.strokeMiterlimit "10"
                        , SvgAttr.x1 "1"
                        , SvgAttr.y1 "1"
                        , SvgAttr.x2 "13"
                        , SvgAttr.y2 "1"
                        ]
                        []
                    ]
                ]
            , div
                [ class "icon-wrapper icon-wrapper--titlebar icon-wrapper--double--right"
                , style "padding-right" "4vw"
                , onClick CloseWindow
                ]
                [ svg
                    [ SvgAttr.version "1.2"
                    , SvgAttr.baseProfile "tiny"
                    , SvgAttr.id "Layer_1"
                    , SvgAttr.x "0px"
                    , SvgAttr.y "0px"
                    , SvgAttr.viewBox "0 0 12.6 12.6"
                    , SvgAttr.xmlSpace "preserve"
                    , SvgAttr.height "4.2vw"
                    , SvgAttr.class "icon icon--close"
                    ]
                    [ Svg.line
                        [ SvgAttr.fill "none"
                        , SvgAttr.stroke "#F6F2EB"
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.strokeLinecap "round"
                        , SvgAttr.strokeMiterlimit "10"
                        , SvgAttr.x1 "1"
                        , SvgAttr.y1 "1"
                        , SvgAttr.x2 "11.6"
                        , SvgAttr.y2 "11.6"
                        ]
                        []
                    , Svg.line
                        [ SvgAttr.fill "none"
                        , SvgAttr.stroke "#F6F2EB"
                        , SvgAttr.strokeWidth "2"
                        , SvgAttr.strokeLinecap "round"
                        , SvgAttr.strokeMiterlimit "10"
                        , SvgAttr.x1 "11.6"
                        , SvgAttr.y1 "1"
                        , SvgAttr.x2 "1"
                        , SvgAttr.y2 "11.6"
                        ]
                        []
                    ]
                ]
            ]
        ]


timerSettingView : Model -> Html Msg
timerSettingView model =
    div [ class "container" ]
        [ p
            [ class "drawer-heading"
            ]
            [ text "Timer" ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Focus" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , value <| String.fromFloat (toFloat model.config.pomodoroDuration / 60)
                    , onInput <| UpdateSetting FocusTime
                    , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.pomodoroDuration / 60)) ++ "ch"
                    ]
                    []
                , text ":00"
                ]
            , div
                [ class "slider-wrapper"
                ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , Html.Attributes.step "1"
                    , class "slider slider--red"
                    , value <| String.fromFloat (toFloat model.config.pomodoroDuration / 60)
                    , onInput <| UpdateSetting FocusTime
                    ]
                    []
                , div
                    [ class "slider-bar slider-bar--red"
                    , style "width" (String.fromFloat ((100 * (toFloat model.config.pomodoroDuration / 60) / 90) - 0.5) ++ "%")
                    ]
                    []
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Short Break" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , value <| String.fromFloat (toFloat model.config.shortBreakDuration / 60)
                    , onInput <| UpdateSetting ShortBreakTime
                    , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.shortBreakDuration / 60)) ++ "ch"
                    ]
                    []
                , text ":00"
                ]
            , div
                [ class "slider-wrapper"
                ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , Html.Attributes.step "1"
                    , class "slider slider--green"
                    , value <| String.fromFloat (toFloat model.config.shortBreakDuration / 60)
                    , onInput <| UpdateSetting ShortBreakTime
                    ]
                    []
                , div
                    [ class "slider-bar slider-bar--green"
                    , style "width" (String.fromFloat ((100 * (toFloat model.config.shortBreakDuration / 60) / 90) - 0.5) ++ "%")
                    ]
                    []
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Long Break" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , value <| String.fromFloat (toFloat model.config.longBreakDuration / 60)
                    , onInput <| UpdateSetting LongBreakTime
                    , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.longBreakDuration / 60)) ++ "ch"
                    ]
                    []
                , text ":00"
                ]
            , div
                [ class "slider-wrapper"
                ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "1"
                    , Html.Attributes.max "90"
                    , Html.Attributes.step "1"
                    , class "slider slider--blue"
                    , value <| String.fromFloat (toFloat model.config.longBreakDuration / 60)
                    , onInput <| UpdateSetting LongBreakTime
                    ]
                    []
                , div
                    [ class "slider-bar slider-bar--blue"
                    , style "width" (String.fromFloat ((100 * (toFloat model.config.longBreakDuration / 60) / 90) - 0.5) ++ "%")
                    ]
                    []
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Rounds" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , Html.Attributes.min "0"
                    , Html.Attributes.max "12"
                    , Html.Attributes.step "1"
                    , value <| String.fromInt model.config.maxRoundNumber
                    , onInput <| UpdateSetting Rounds
                    , style "width" <| String.fromInt (String.length <| String.fromInt model.config.maxRoundNumber) ++ "ch"
                    ]
                    []
                ]
            , div
                [ class "slider-wrapper"
                ]
                [ input
                    [ type_ "range"
                    , Html.Attributes.min "0"
                    , Html.Attributes.max "12"
                    , Html.Attributes.step "1"
                    , class "slider"
                    , value <| String.fromInt model.config.maxRoundNumber
                    , onInput <| UpdateSetting Rounds
                    ]
                    []
                , div
                    [ class "slider-bar slider-bar--blue-grey"
                    , style "width" (String.fromFloat (100 * toFloat model.config.maxRoundNumber / 12) ++ "%")
                    ]
                    []
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "text-button"
                , onClick ResetSettings
                ]
                [ text "Reset Defaults" ]
            ]
        ]


settingsSettingView : Model -> Html Msg
settingsSettingView model =
    let
        settingWrapper : String -> Msg -> Bool -> Html Msg
        settingWrapper title msg settingActive =
            div
                [ class "setting-wrapper"
                , onClick msg
                ]
                [ p [ class "setting-title" ] [ text title ]
                , div
                    [ class "checkbox"
                    , class <|
                        if settingActive then
                            "is-active"

                        else
                            "is-inactive"
                    ]
                    []
                ]
    in
    div [ class "container", id "settings" ]
        [ p
            [ class "drawer-heading"
            ]
            [ text "Settings" ]
        , settingWrapper "Always On Top" (ChangeSettingConfig AlwaysOnTop) model.config.alwaysOnTop
        , settingWrapper "Auto-start Work Timer" (ChangeSettingConfig AutoStartWorkTimer) model.config.autoStartWorkTimer
        , settingWrapper "Auto-start Break Timer" (ChangeSettingConfig AutoStartBreakTimer) model.config.autoStartBreakTimer
        , settingWrapper "Tick Sounds - Work" (ChangeSettingConfig TickSoundsDuringWork) model.config.tickSoundsDuringWork
        , settingWrapper "Tick Sounds - Break" (ChangeSettingConfig TickSoundsDuringBreak) model.config.tickSoundsDuringBreak
        , settingWrapper "Desktop Notifications" (ChangeSettingConfig DesktopNotifications) model.config.desktopNotifications
        , settingWrapper "Minimize to Tray" (ChangeSettingConfig MinimizeToTray) model.config.minimizeToTray
        , settingWrapper "Minimize to Tray on Close" (ChangeSettingConfig MinimizeToTrayOnClose) model.config.minimizeToTrayOnClose
        ]


aboutSettingView : String -> Html Msg
aboutSettingView appVersion =
    div [ class "container", id "about" ]
        [ p [ class "drawer-heading" ] [ text "About" ]
        , section []
            [ h2 [] [ text "Pomodrolm" ]
            , p [ class "label" ]
                [ text <| "Version: " ++ appVersion ++ " "
                , a
                    [ href <| "https://github.com/vjousse/pomodorolm/releases/tag/app-v" ++ appVersion
                    , class "label"
                    , class "link"
                    , target "_blank"
                    ]
                    [ text "(release notes)" ]
                ]
            , p [ class "label" ]
                [ a
                    [ href "https://github.com/vjousse/pomodorolm"
                    , class "label"
                    , class "link"
                    , target "_blank"
                    ]
                    [ text "Licence, Documentation and Source Code" ]
                ]
            ]
        ]


themeSettingView : Model -> Html Msg
themeSettingView model =
    div [ class "container", id "theme" ]
        (p [ class "drawer-heading" ] [ text "Themes" ]
            :: (model.themes
                    |> ListWithCurrent.toList
                    |> List.map
                        (\t ->
                            let
                                name =
                                    t.name

                                colors =
                                    t.colors
                            in
                            div
                                [ class "setting-wrapper"
                                , style "background-color" colors.background
                                , style "border-color" colors.accent
                                , onClick <| ChangeTheme t
                                ]
                                [ p
                                    [ class "setting-title"
                                    , style "color" colors.foreground
                                    ]
                                    [ text name ]
                                , if t == model.theme then
                                    svg
                                        [ SvgAttr.viewBox "0 0 24 24"
                                        , SvgAttr.width "5vw"
                                        ]
                                        [ path [ SvgAttr.fill colors.accent, SvgAttr.d "M9 16.2L4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4L9 16.2z" ] [] ]

                                  else
                                    text ""
                                ]
                        )
               )
        )


drawerView : Model -> Html Msg
drawerView model =
    div
        [ id "drawer"
        ]
        [ case model.settingTab of
            ThemeTab ->
                themeSettingView model

            TimerTab ->
                timerSettingView model

            SettingsTab ->
                settingsSettingView model

            AboutTab ->
                aboutSettingView model.appVersion
        , div
            [ class "drawer-menu"
            ]
            [ div
                [ title "Timer Configuration"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == TimerTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab TimerTab
                ]
                [ div
                    [ class "drawer-menu-button"
                    ]
                    [ div
                        [ class "icon-wrapper"
                        ]
                        [ svg
                            [ SvgAttr.version "1.2"
                            , SvgAttr.baseProfile "tiny"
                            , SvgAttr.id "timer-icon"
                            , SvgAttr.x "0px"
                            , SvgAttr.y "0px"
                            , SvgAttr.viewBox "0 0 20 20"
                            , SvgAttr.width "5vw"
                            , SvgAttr.xmlSpace "preserve"
                            , SvgAttr.class "icon"
                            ]
                            [ Svg.g []
                                [ path
                                    [ SvgAttr.fill "var(--color-background-lightest)"
                                    , SvgAttr.d "M10,0C4.5,0,0,4.5,0,10s4.5,10,10,10c5.5,0,10-4.5,10-10S15.5,0,10,0z M10,18c-4.4,0-8-3.6-8-8s3.6-8,8-8\n              s8,3.6,8,8S14.4,18,10,18z"
                                    ]
                                    []
                                , path
                                    [ SvgAttr.fill "var(--color-background-lightest)"
                                    , SvgAttr.d "M10.5,5H9v6l5.3,3.1l0.8-1.2l-4.5-2.7V5z"
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            , div
                [ title "Options"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == SettingsTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab SettingsTab
                ]
                [ div
                    [ class "drawer-menu-button"
                    ]
                    [ svg
                        [ SvgAttr.version "1.2"
                        , SvgAttr.baseProfile "tiny"
                        , SvgAttr.id "settings-icon"
                        , SvgAttr.x "0px"
                        , SvgAttr.y "0px"
                        , SvgAttr.viewBox "0 0 19.5 20"
                        , SvgAttr.width "5vw"
                        , SvgAttr.xmlSpace "preserve"
                        , SvgAttr.class "icon"
                        ]
                        [ path
                            [ SvgAttr.fill "var(--color-background-lightest)"
                            , SvgAttr.d "M17.2,11c0-0.3,0.1-0.6,0.1-1s0-0.7-0.1-1l2.1-1.6c0.2-0.1,0.2-0.4,0.1-0.6l-2-3.5C17.3,3.1,17,3,16.8,3.1\n          l-2.5,1c-0.5-0.4-1.1-0.7-1.7-1l-0.4-2.7C12.2,0.2,12,0,11.7,0h-4C7.5,0,7.3,0.2,7.2,0.4L6.9,3.1c-0.6,0.3-1.2,0.6-1.7,1l-2.5-1\n          C2.4,3,2.2,3.1,2.1,3.3l-2,3.5C-0.1,6.9,0,7.2,0.2,7.4L2.3,9c0,0.3-0.1,0.6-0.1,1s0,0.7,0.1,1l-2.1,1.6C0,12.8-0.1,13,0.1,13.3\n          l2,3.5c0.1,0.2,0.4,0.3,0.6,0.2l2.5-1c0.5,0.4,1.1,0.7,1.7,1l0.4,2.6c0,0.2,0.2,0.4,0.5,0.4h4c0.3,0,0.5-0.2,0.5-0.4l0.4-2.6\n          c0.6-0.3,1.2-0.6,1.7-1l2.5,1c0.2,0.1,0.5,0,0.6-0.2l2-3.5c0.1-0.2,0.1-0.5-0.1-0.6L17.2,11z M9.7,13.5c-1.9,0-3.5-1.6-3.5-3.5\n          s1.6-3.5,3.5-3.5s3.5,1.6,3.5,3.5S11.7,13.5,9.7,13.5z"
                            ]
                            []
                        ]
                    ]
                ]
            , div
                [ title "Options"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == ThemeTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab ThemeTab
                ]
                [ div
                    [ class "drawer-menu-button"
                    ]
                    [ svg
                        [ SvgAttr.version "1.2"
                        , SvgAttr.baseProfile "tiny"
                        , SvgAttr.id "theme-icon"
                        , SvgAttr.x "0px"
                        , SvgAttr.y "0px"
                        , SvgAttr.viewBox "0 0 19.5 20"
                        , SvgAttr.width "5vw"
                        , SvgAttr.xmlSpace "preserve"
                        , SvgAttr.class "icon"
                        ]
                        [ path
                            [ SvgAttr.fill "var(--color-background-lightest)"
                            , SvgAttr.d "M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9c.83 0 1.5-.67 1.5-1.5 0-.39-.15-.74-.39-1.01-.23-.26-.38-.61-.38-.99 0-.83.67-1.5 1.5-1.5H16c2.76 0 5-2.24 5-5 0-4.42-4.03-8-9-8zm-5.5 9c-.83 0-1.5-.67-1.5-1.5S5.67 9 6.5 9 8 9.67 8 10.5 7.33 12 6.5 12zm3-4C8.67 8 8 7.33 8 6.5S8.67 5 9.5 5s1.5.67 1.5 1.5S10.33 8 9.5 8zm5 0c-.83 0-1.5-.67-1.5-1.5S13.67 5 14.5 5s1.5.67 1.5 1.5S15.33 8 14.5 8zm3 4c-.83 0-1.5-.67-1.5-1.5S16.67 9 17.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"
                            ]
                            []
                        ]
                    ]
                ]
            , div
                [ title "About"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == AboutTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab AboutTab
                ]
                [ div
                    [ class "Drawer-menu-button"
                    ]
                    [ div
                        [ class "icon-wrapper"
                        ]
                        [ svg
                            [ SvgAttr.id "about-icon"
                            , SvgAttr.width "6.6vw"
                            , SvgAttr.height "6.6vw"
                            , SvgAttr.viewBox "0 0 24 24"
                            , SvgAttr.class "icon"
                            ]
                            [ path
                                [ SvgAttr.fill "none"
                                , SvgAttr.d "M0 0h24v24H0V0z"
                                ]
                                []
                            , path
                                [ SvgAttr.fill "var(--color-background-lightest)"
                                , SvgAttr.d "M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            ]
        ]


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ navView model
        , if model.drawerOpen then
            drawerView model

          else
            timerView model
        ]



-- SUBSCRIPTIONS


mapLoadConfig : Decode.Value -> Msg
mapLoadConfig modelJson =
    case Decode.decodeValue configDecoder modelJson of
        Ok model ->
            LoadConfig model

        Err _ ->
            --@FIX: don't fail silently
            NoOp


mapLoadThemes : Decode.Value -> Msg
mapLoadThemes modelJson =
    case Decode.decodeValue themesDecoder modelJson of
        Ok themes ->
            LoadThemes themes

        Err _ ->
            --@FIX: don't fail silently
            NoOp


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ tick Tick
        , loadConfig mapLoadConfig
        , loadThemes mapLoadThemes
        ]


port tick : (String -> msg) -> Sub msg


port loadConfig : (Decode.Value -> msg) -> Sub msg


port loadThemes : (Decode.Value -> msg) -> Sub msg



-- PORTS


port playSound : String -> Cmd msg


port playTick : Bool -> Cmd msg


port setVolume : Float -> Cmd msg


port closeWindow : () -> Cmd msg


port loadRustConfig : () -> Cmd msg


port minimizeWindow : () -> Cmd msg


port hideWindow : () -> Cmd msg


port updateCurrentState : CurrentState -> Cmd msg


port notify : Notification -> Cmd msg


port updateConfig : Config -> Cmd msg


port setThemeColors : ThemeColors -> Cmd msg
