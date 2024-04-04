port module Main exposing (..)

import Browser
import Html exposing (Html, a, div, h1, h2, input, nav, p, section, text)
import Html.Attributes exposing (class, href, id, style, target, title, type_, value)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Time


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
    { config : Config
    , currentColor : Color
    , currentRoundNumber : Int
    , currentSessionType : SessionType
    , currentTime : Seconds
    , drawerOpen : Bool
    , endColor : Color
    , initialColor : Color
    , middleColor : Color
    , muted : Bool
    , sessionStatus : SessionStatus
    , settingTab : SettingTab
    , strokeDasharray : Float
    , volume : Float
    , volumeSliderHidden : Bool
    }


type alias Color =
    { r : Int, g : Int, b : Int }


type alias Config =
    { alwaysOnTop : Bool
    , autoStartWorkTimer : Bool
    , autoStartBreakTimer : Bool
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , tickSoundsDuringWork : Bool
    , tickSoundsDuringBreak : Bool
    }


type alias CurrentState =
    { color : Color, percentage : Float, paused : Bool }


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


type alias NextRoundInfo =
    { nextSessionType : SessionType
    , htmlIdOfAudioToPlay : String
    , nextRoundNumber : Int
    , nextTime : Seconds
    }


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
    }


type alias Flags =
    { alwaysOnTop : Bool
    , autoStartWorkTimer : Bool
    , autoStartBreakTimer : Bool
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
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


green : Color
green =
    { r = 5, g = 236, b = 140 }


orange : Color
orange =
    { r = 255, g = 127, b = 14 }


red : Color
red =
    { r = 255, g = 78, b = 77 }


blue : Color
blue =
    { r = 11, g = 189, b = 219 }


pink : Color
pink =
    { r = 255, g = 137, b = 167 }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { config =
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
            , tickSoundsDuringWork = flags.tickSoundsDuringWork
            , tickSoundsDuringBreak = flags.tickSoundsDuringBreak
            }
      , currentColor = green
      , currentRoundNumber = 1
      , currentSessionType = Pomodoro
      , currentTime = flags.pomodoroDuration
      , drawerOpen = False
      , endColor = red
      , initialColor = green
      , middleColor = orange
      , muted = False
      , sessionStatus = Stopped
      , settingTab = TimerTab
      , strokeDasharray = 691.3321533203125
      , volume = 1
      , volumeSliderHidden = True
      }
    , updateCurrentState { color = green, percentage = 1, paused = False }
    )


type SettingType
    = FocusTime
    | ShortBreakTime
    | LongBreakTime
    | Rounds


type Msg
    = CloseWindow
    | ChangeSettingTab SettingTab
    | ChangeSettingConfig Setting
    | HideVolumeBar
    | MinimizeWindow
    | Reset
    | ResetSettings
    | SkipCurrentRound
    | ShowVolumeBar
    | Tick Time.Posix
    | ToggleDrawer
    | ToggleMute
    | ToggleStatus
    | UpdateVolume String
    | UpdateSetting SettingType String


getNextRoundInfo : Model -> NextRoundInfo
getNextRoundInfo model =
    case model.currentSessionType of
        Pomodoro ->
            if model.currentRoundNumber == model.config.maxRoundNumber then
                { nextSessionType = LongBreak
                , htmlIdOfAudioToPlay = "audio-long-break"
                , nextRoundNumber = model.currentRoundNumber
                , nextTime = model.config.longBreakDuration
                }

            else
                { nextSessionType = ShortBreak
                , htmlIdOfAudioToPlay = "audio-short-break"
                , nextRoundNumber = model.currentRoundNumber
                , nextTime = model.config.shortBreakDuration
                }

        ShortBreak ->
            { nextSessionType = Pomodoro
            , htmlIdOfAudioToPlay = "audio-work"
            , nextRoundNumber = model.currentRoundNumber + 1
            , nextTime = model.config.pomodoroDuration
            }

        LongBreak ->
            { nextSessionType = Pomodoro
            , htmlIdOfAudioToPlay = "audio-work"
            , nextRoundNumber = 1
            , nextTime = model.config.pomodoroDuration
            }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
            in
            ( { model | config = newSettingsConfig }, updateConfig newSettingsConfig )

        ChangeSettingTab settingTab ->
            ( { model | settingTab = settingTab }, Cmd.none )

        CloseWindow ->
            ( model, closeWindow () )

        HideVolumeBar ->
            ( { model | volumeSliderHidden = True }, Cmd.none )

        MinimizeWindow ->
            ( model, minimizeWindow () )

        Reset ->
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
            , updateCurrentState
                { color = colorForSessionType model.currentSessionType
                , percentage = 100
                , paused =
                    if model.sessionStatus == Paused then
                        True

                    else
                        False
                }
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
            in
            ( { model
                | config = newConfig
                , currentTime = defaults.pomodoroDuration
                , currentSessionType = Pomodoro
                , sessionStatus = Stopped
              }
            , Cmd.none
            )

        SkipCurrentRound ->
            let
                nextRoundInfo =
                    getNextRoundInfo model
            in
            ( { model
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
            , Cmd.batch
                [ if model.muted then
                    Cmd.none

                  else
                    playSound nextRoundInfo.htmlIdOfAudioToPlay
                , updateCurrentState
                    { color = colorForSessionType nextRoundInfo.nextSessionType
                    , percentage = 100
                    , paused =
                        if model.sessionStatus == Paused then
                            True

                        else
                            False
                    }
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
                        computeCurrentColor newTime maxTime model.currentSessionType

                    percent =
                        1 * toFloat newTime / toFloat maxTime
                in
                ( { model | currentTime = newTime, currentColor = currentColor }
                , Cmd.batch
                    [ if model.config.tickSoundsDuringWork && not model.muted then
                        playSound "audio-tick"

                      else
                        Cmd.none
                    , updateCurrentState
                        { color = currentColor
                        , percentage = percent
                        , paused =
                            if model.sessionStatus == Paused then
                                True

                            else
                                False
                        }
                    ]
                )

            else if model.currentTime == 0 then
                let
                    nextRoundInfo =
                        getNextRoundInfo model
                in
                ( { model
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
                , if model.muted then
                    Cmd.none

                  else
                    playSound nextRoundInfo.htmlIdOfAudioToPlay
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
            in
            ( { model | muted = not model.muted, volume = newVolume }
            , setVolume newVolume
            )

        ToggleStatus ->
            case model.sessionStatus of
                Running ->
                    ( { model | sessionStatus = Paused }
                    , updateCurrentState
                        { color = computeCurrentColor model.currentTime (getCurrentMaxTime model) model.currentSessionType
                        , percentage = 1 * toFloat model.currentTime / toFloat (getCurrentMaxTime model)
                        , paused = True
                        }
                    )

                _ ->
                    ( { model | sessionStatus = Running }
                    , updateCurrentState
                        { color = computeCurrentColor model.currentTime (getCurrentMaxTime model) model.currentSessionType
                        , percentage = 1 * toFloat model.currentTime / toFloat (getCurrentMaxTime model)
                        , paused = False
                        }
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


colorForSessionType : SessionType -> Color
colorForSessionType sessionType =
    case sessionType of
        Pomodoro ->
            green

        ShortBreak ->
            pink

        LongBreak ->
            blue


computeCurrentColor : Seconds -> Seconds -> SessionType -> Color
computeCurrentColor currentTime maxTime sessionType =
    let
        percent =
            1 * toFloat currentTime / toFloat maxTime

        relativePercent =
            1 * (toFloat currentTime - toFloat maxTime / 2) / (toFloat maxTime / 2)
    in
    case sessionType of
        Pomodoro ->
            if percent > 0.5 then
                { r = toFloat orange.r + (relativePercent * toFloat (green.r - orange.r)) |> round
                , g = toFloat orange.g + (relativePercent * toFloat (green.g - orange.g)) |> round
                , b = toFloat orange.b + (relativePercent * toFloat (green.b - orange.b)) |> round
                }

            else
                { r = toFloat red.r + ((1 + relativePercent) * toFloat (orange.r - red.r)) |> round
                , g = toFloat red.g + ((1 + relativePercent) * toFloat (orange.g - red.g)) |> round
                , b = toFloat red.b + ((1 + relativePercent) * toFloat (orange.b - red.b)) |> round
                }

        s ->
            colorForSessionType s


secondsToString : Seconds -> String
secondsToString seconds =
    (String.padLeft 2 '0' <| String.fromInt (seconds // 60)) ++ ":" ++ (String.padLeft 2 '0' <| String.fromInt (modBy 60 seconds))


dialView : SessionType -> Seconds -> Seconds -> Float -> Html Msg
dialView sessionType currentTime maxTime maxStrokeDasharray =
    let
        percent =
            1 * toFloat currentTime / toFloat maxTime

        strokeDasharray =
            maxStrokeDasharray - maxStrokeDasharray * percent

        colorToHtmlRgbString c =
            "rgb(" ++ String.fromInt c.r ++ ", " ++ String.fromInt c.g ++ ", " ++ String.fromInt c.b ++ ")"

        color =
            colorToHtmlRgbString <| computeCurrentColor currentTime maxTime sessionType
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
            , SvgAttr.width "220"
            , SvgAttr.height "220"
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
            , SvgAttr.width "220"
            , SvgAttr.height "220"
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
                , SvgAttr.height "15px"
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
                , SvgAttr.height "15px"
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
                    , SvgAttr.height "15px"
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
                        , SvgAttr.height "15px"
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
                        , SvgAttr.height "20px"
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
        [ dialView model.currentSessionType model.currentTime (getCurrentMaxTime model) model.strokeDasharray
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
        , h1 [ class "title" ] [ text "Pomodorolm" ]
        , div [ class "icon-group" ]
            [ div [ class "icon-wrapper icon-wrapper--titlebar icon-wrapper--double--left", style "padding-left" "18px", onClick MinimizeWindow ]
                [ svg
                    [ SvgAttr.version "1.2"
                    , SvgAttr.baseProfile "tiny"
                    , SvgAttr.id "Layer_1"
                    , SvgAttr.x "0px"
                    , SvgAttr.y "0px"
                    , SvgAttr.viewBox "0 0 14 2"
                    , SvgAttr.xmlSpace "preserve"
                    , SvgAttr.width "15px"
                    , SvgAttr.height "20px"
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
                , style "padding-right" "18px"
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
                    , SvgAttr.height "15px"
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


aboutSettingView : Html Msg
aboutSettingView =
    div [ class "container", id "about" ]
        [ p [ class "drawer-heading" ] [ text "About" ]
        , section []
            [ h2 [] [ text "Pomodrolm" ]
            , p [ class "label" ] [ text "Version: dev" ]
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


drawerView : Model -> Html Msg
drawerView model =
    div
        [ id "drawer"
        ]
        [ case model.settingTab of
            TimerTab ->
                timerSettingView model

            SettingsTab ->
                settingsSettingView model

            AboutTab ->
                aboutSettingView
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
                            , SvgAttr.width "18"
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
                        , SvgAttr.width "18"
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
                            , SvgAttr.width "24"
                            , SvgAttr.height "24"
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- PORTS


port playSound : String -> Cmd msg


port setVolume : Float -> Cmd msg


port closeWindow : () -> Cmd msg


port minimizeWindow : () -> Cmd msg


port updateCurrentState : CurrentState -> Cmd msg


port updateConfig : Config -> Cmd msg
