module View.Timer exposing (timerView)

import ColorHelper exposing (computeCurrentColor)
import Html exposing (Html, div, input, p, section, text)
import Html.Attributes exposing (class, id, style, title, type_, value)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Themes exposing (Theme)
import TimeHelper exposing (getCurrentMaxTime)
import Types exposing (Model, Msg(..), RGB(..), ResetType(..), Seconds, SessionStatus(..), SessionType(..))


dialView : SessionType -> Seconds -> Seconds -> Float -> Theme -> String -> String -> String -> Html Msg
dialView sessionType currentTime maxTime maxStrokeDasharray theme focusLabel shortBreakLabel longBreakLabel =
    let
        remainingPercent =
            if maxTime /= 0 then
                toFloat (maxTime - currentTime) / toFloat maxTime

            else
                1

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
            [ input
                [ type_ "text"
                , value
                    (case sessionType of
                        Focus ->
                            focusLabel

                        ShortBreak ->
                            shortBreakLabel

                        LongBreak ->
                            longBreakLabel
                    )
                , style "color" color
                , onInput <| UpdateLabel sessionType
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


timerView : Model -> Html Msg
timerView ({ config, strokeDasharray, theme, pomodoroState, focusLabel, shortBreakLabel, longBreakLabel } as model) =
    let
        _ =
            Debug.log "Pomodoro state" pomodoroState
    in
    pomodoroState
        |> Maybe.map
            (\state ->
                div [ class "timer-wrapper" ]
                    [ dialView state.currentSession.sessionType state.currentSession.currentTime (getCurrentMaxTime config state) strokeDasharray theme focusLabel shortBreakLabel longBreakLabel
                    , playPauseView state.currentSession.status
                    , footerView model
                    ]
            )
        |> Maybe.withDefault
            (div
                [ class "timer-wrapper" ]
                [ div [] [ text "" ], footerView model ]
            )


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
            [ p [ class "total-rounds" ] [ text <| String.fromInt (model.pomodoroState |> Maybe.map (\state -> state.currentWorkRoundNumber) |> Maybe.withDefault 1) ++ "/" ++ String.fromInt model.config.maxRoundNumber ]
            , div [ class "reset-rounds" ]
                [ p [ class "text-button", title "Reset current round", onClick <| Reset CurrentRound ] [ text "Reset round" ]
                , text " or "
                , p [ class "text-button", title "Reset the whole session", onClick <| Reset EntireSession ] [ text "session" ]
                ]
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


secondsToString : Seconds -> String
secondsToString seconds =
    (String.padLeft 2 '0' <| String.fromInt (seconds // 60)) ++ ":" ++ (String.padLeft 2 '0' <| String.fromInt (modBy 60 seconds))
