module View.Drawer exposing (drawerView)

import Html exposing (Html, a, div, h2, input, p, section, span, text)
import Html.Attributes exposing (class, href, id, style, target, title, type_, value)
import Html.Events exposing (onClick, onInput)
import ListWithCurrent
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Types exposing (Model, Msg(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..))


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


audioFileWrapper : Maybe String -> SessionType -> String -> Html Msg
audioFileWrapper audioFile sessionType soundTitle =
    div [ class "setting-wrapper-multi" ]
        [ div
            [ class "setting-wrapper"
            ]
            [ p [ class "setting-title" ] [ span [ style "font-weight" "bold" ] [ text soundTitle ], text " start sound" ]
            , p [ class "setting-title" ]
                [ a
                    [ class
                        ("setting-button left"
                            ++ (case audioFile of
                                    Nothing ->
                                        " active"

                                    _ ->
                                        ""
                               )
                        )
                    , title "Reset to default sound"
                    , onClick <| ResetAudioFile sessionType
                    ]
                    [ text "default" ]
                , a
                    [ class
                        ("setting-button right"
                            ++ (case audioFile of
                                    Just _ ->
                                        " active"

                                    _ ->
                                        ""
                               )
                        )
                    , title "Choose custom sound"
                    , onClick <| AudioFileRequested sessionType
                    ]
                    [ text "custom" ]
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p [ class "setting-title" ]
                [ span []
                    [ text
                        (case audioFile of
                            Just fileName ->
                                "Using custom " ++ fileName

                            Nothing ->
                                "Using default"
                        )
                    ]
                ]
            ]
        ]


drawerView : Model -> Html Msg
drawerView model =
    div
        [ id "drawer"
        ]
        [ case model.settingTab of
            AboutTab ->
                aboutSettingView model.appVersion

            SettingsTab ->
                settingsSettingView model

            SoundsTab ->
                soundsSettingView model

            TextTab ->
                textSettingView model

            ThemeTab ->
                themeSettingView model

            TimerTab ->
                timerSettingView model
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
                [ title "Sounds"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == SoundsTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab SoundsTab
                ]
                [ div
                    [ class "drawer-menu-button"
                    ]
                    [ div
                        [ class "icon-wrapper"
                        ]
                        [ svg
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
                        ]
                    ]
                ]
            , div
                [ title "Text"
                , class "drawer-menu-wrapper"
                , class
                    (if model.settingTab == TextTab then
                        "is-active"

                     else
                        ""
                    )
                , onClick <| ChangeSettingTab TextTab
                ]
                [ div
                    [ class "drawer-menu-button"
                    ]
                    [ div
                        [ class "icon-wrapper"
                        ]
                        [ svg
                            [ SvgAttr.width "6.6vw"
                            , SvgAttr.height "6.6vw"
                            , SvgAttr.viewBox "0 0 24 24"
                            , SvgAttr.class "icon"
                            , SvgAttr.fill "none"
                            ]
                            [ path
                                [ SvgAttr.d "M12 3v18m-3 0h6m4-15V3H5v3"
                                , SvgAttr.stroke "var(--color-background-lightest)"
                                , SvgAttr.strokeWidth "2"
                                , SvgAttr.strokeLinecap "round"
                                , SvgAttr.strokeLinejoin "round"
                                ]
                                []
                            ]
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
                    [ class "drawer-menu-button"
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
                    , value <| String.fromFloat (toFloat model.config.focusDuration / 60)
                    , onInput <| FocusTime >> UpdateSetting
                    , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.focusDuration / 60)) ++ "ch"
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
                    , value <| String.fromFloat (toFloat model.config.focusDuration / 60)
                    , onInput <| FocusTime >> UpdateSetting
                    ]
                    []
                , div
                    [ class "slider-bar slider-bar--red"
                    , style "width" (String.fromFloat ((100 * (toFloat model.config.focusDuration / 60) / 90) - 0.5) ++ "%")
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
                    , onInput <| ShortBreakTime >> UpdateSetting
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
                    , onInput <| ShortBreakTime >> UpdateSetting
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
                    , onInput <| LongBreakTime >> UpdateSetting
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
                    , onInput <| LongBreakTime >> UpdateSetting
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
                    , onInput <| Rounds >> UpdateSetting
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
                    , onInput <| Rounds >> UpdateSetting
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
    div [ class "container", id "settings" ]
        [ p
            [ class "drawer-heading"
            ]
            [ text "General Settings" ]
        , settingWrapper "Always On Top" (UpdateSetting <| Toggle AlwaysOnTop) model.config.alwaysOnTop
        , settingWrapper "Auto-start Work Timer" (UpdateSetting <| Toggle AutoStartWorkTimer) model.config.autoStartWorkTimer
        , settingWrapper "Auto-start Break Timer" (UpdateSetting <| Toggle AutoStartBreakTimer) model.config.autoStartBreakTimer
        , settingWrapper "Auto-start the app on system startup" (UpdateSetting <| Toggle SystemStartupAutoStart) model.config.systemStartupAutoStart
        , settingWrapper "Desktop Notifications" (UpdateSetting <| Toggle DesktopNotifications) model.config.desktopNotifications
        , settingWrapper "Minimize to Tray" (UpdateSetting <| Toggle MinimizeToTray) model.config.minimizeToTray
        , settingWrapper "Minimize to Tray on Close" (UpdateSetting <| Toggle MinimizeToTrayOnClose) model.config.minimizeToTrayOnClose
        , settingWrapper "Start minimized to Tray" (UpdateSetting <| Toggle StartMinimized) model.config.startMinimized
        ]


soundsSettingView : Model -> Html Msg
soundsSettingView model =
    div [ class "container", id "sound-settings" ]
        [ p
            [ class "drawer-heading"
            ]
            [ text "Sound Settings" ]
        , settingWrapper "Tick Sounds - Break" (UpdateSetting <| Toggle TickSoundsDuringBreak) model.config.tickSoundsDuringBreak
        , settingWrapper "Tick Sounds - Work" (UpdateSetting <| Toggle TickSoundsDuringWork) model.config.tickSoundsDuringWork
        , audioFileWrapper model.config.shortBreakAudio ShortBreak "Short break"
        , audioFileWrapper model.config.longBreakAudio LongBreak "Long break"
        , audioFileWrapper model.config.focusAudio Focus "Work session"
        ]


textSettingView : Model -> Html Msg
textSettingView model =
    div [ class "container", id "text-settings" ]
        [ p
            [ class "drawer-heading"
            ]
            [ text "Text Settings" ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Default focus label" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , value model.config.defaultFocusLabel
                    , onInput <| Label Focus >> UpdateSetting
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
                [ text "Default short break label" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , value model.config.defaultShortBreakLabel
                    , onInput <| Label ShortBreak >> UpdateSetting

                    -- , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.focusDuration / 60)) ++ "ch"
                    ]
                    []

                -- , text ":00"
                ]
            ]
        , div
            [ class "setting-wrapper"
            ]
            [ p
                [ class "setting-title"
                ]
                [ text "Default long break label" ]
            , p
                [ class "setting-value"
                ]
                [ input
                    [ type_ "text"
                    , class "setting-input"
                    , value model.config.defaultLongBreakLabel
                    , onInput <| Label LongBreak >> UpdateSetting

                    -- , style "width" <| String.fromInt (String.length <| String.fromFloat (toFloat model.config.focusDuration / 60)) ++ "ch"
                    ]
                    []

                -- , text ":00"
                ]
            ]
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
