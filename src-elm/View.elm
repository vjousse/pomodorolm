module View exposing (drawerView, navView, timerView)

import ColorHelper exposing (computeCurrentColor)
import Html exposing (Html, a, div, h1, h2, input, nav, p, section, text)
import Html.Attributes exposing (attribute, class, href, id, style, target, title, type_, value)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import ListWithCurrent
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Themes exposing (Theme)
import TimeHelper exposing (getCurrentMaxTime)
import Types exposing (Model, Msg(..), RGB(..), Seconds, SessionStatus(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..))


dialView : SessionType -> Seconds -> Seconds -> Float -> Theme -> Html Msg
dialView sessionType currentTime maxTime maxStrokeDasharray theme =
    let
        remainingPercent =
            toFloat (maxTime - currentTime) / toFloat maxTime

        strokeDasharray =
            maxStrokeDasharray - maxStrokeDasharray * remainingPercent

        colorToHtmlRgbString (RGB r g b) =
            "rgb(" ++ String.fromInt r ++ ", " ++ String.fromInt g ++ ", " ++ String.fromInt b ++ ")"

        color =
            colorToHtmlRgbString <| computeCurrentColor currentTime maxTime sessionType theme
    in
    div [ class "dial-wrapper" ]
        [ p [ class "dial-time" ]
            [ text <| secondsToString (maxTime - currentTime) ]
        , p [ class "dial-label", style "color" color ]
            [ text <|
                case sessionType of
                    Focus ->
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
    section [ class "container", class "button-wrapper" ]
        [ div [ class "button", onClick TogglePlayStatus ]
            [ div [ class "button-icon-wrapper" ]
                [ case sessionStatus of
                    Running ->
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

                    _ ->
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
                ]
            ]
        ]


footerView : Model -> Html Msg
footerView model =
    section [ class "container", class "footer" ]
        [ div [ class "round-wrapper" ]
            [ p [] [ text <| String.fromInt (model.pomodoroState |> Maybe.map (\state -> state.currentWorkRoundNumber) |> Maybe.withDefault 1) ++ "/" ++ String.fromInt model.config.maxRoundNumber ]
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
                [ if model.config.muted == False then
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


timerView : Model -> Html Msg
timerView ({ config, strokeDasharray, theme, pomodoroState } as model) =
    pomodoroState
        |> Maybe.map
            (\state ->
                div [ class "timer-wrapper" ]
                    [ dialView state.currentSession.sessionType state.currentSession.currentTime (getCurrentMaxTime config state) strokeDasharray theme
                    , playPauseView state.currentSession.status
                    , footerView model
                    ]
            )
        |> Maybe.withDefault
            (div
                [ class "timer-wrapper" ]
                [ div [] [ text "Loading state from Rust..." ], footerView model ]
            )


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
        [ p [ class "drawer-heading" ] [ text "Sounds" ]
        , div [ class "setting-wrapper-multi" ]
            [ div
                [ class "setting-wrapper"
                ]
                [ p [ class "setting-title" ] [ text "Short break sound" ]
                , p [ class "setting-title" ]
                    [ a
                        [ class
                            ("setting-button left"
                                ++ (case model.config.shortBreakAudio of
                                        Nothing ->
                                            " active"

                                        _ ->
                                            ""
                                   )
                            )
                        , title "Reset to default sound"
                        , onClick ResetShortBreakAudioFile
                        ]
                        [ text "default" ]
                    , a
                        [ class
                            ("setting-button right"
                                ++ (case model.config.shortBreakAudio of
                                        Just _ ->
                                            " active"

                                        _ ->
                                            ""
                                   )
                            )
                        , title "Choose custom sound"
                        , onClick ShortBreakAudioFileRequested
                        ]
                        [ text "custom" ]
                    ]
                ]
            , div
                [ class "setting-wrapper"
                ]
                [ p [ class "setting-title", style "font-style" "italic" ]
                    [ text
                        (case model.config.shortBreakAudio of
                            Just fileName ->
                                "Using custom sound " ++ fileName

                            Nothing ->
                                "Using default sound"
                        )
                    ]
                ]
            ]
        , p
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


secondsToString : Seconds -> String
secondsToString seconds =
    (String.padLeft 2 '0' <| String.fromInt (seconds // 60)) ++ ":" ++ (String.padLeft 2 '0' <| String.fromInt (modBy 60 seconds))
