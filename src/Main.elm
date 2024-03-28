port module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, nav, p, section, text)
import Html.Attributes exposing (attribute, class, id, style, title)
import Html.Events exposing (onClick)
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Time


main : Program () Model Msg
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
    { currentTime : Seconds
    , currentSessionType : Session
    , longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , sessionStatus : SessionStatus
    , shortBreakDuration : Seconds
    , strokeDasharray : Float
    }


type Session
    = Pomodoro
    | ShortBreak
    | LongBreak


type SessionStatus
    = Paused
    | Stopped
    | Running


init : flags -> ( Model, Cmd Msg )
init _ =
    let
        pomodoroDuration =
            25 * 60
    in
    ( { currentTime = pomodoroDuration
      , currentSessionType = Pomodoro
      , longBreakDuration = 20 * 60
      , pomodoroDuration = pomodoroDuration
      , sessionStatus = Paused
      , shortBreakDuration = 5 * 60
      , strokeDasharray = 691.3321533203125
      }
    , Cmd.none
    )


type Msg
    = Pause
    | Reset
    | Start
    | Stop
    | Tick Time.Posix
    | ToggleStatus


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset ->
            ( { model | currentTime = model.pomodoroDuration }, Cmd.none )

        Tick _ ->
            if model.currentTime > 0 && model.sessionStatus == Running then
                ( { model | currentTime = model.currentTime - 1 }, playSound "audio-tick" )

            else
                ( model, Cmd.none )

        ToggleStatus ->
            case model.sessionStatus of
                Running ->
                    ( { model | sessionStatus = Paused }, Cmd.none )

                _ ->
                    ( { model | sessionStatus = Running }, Cmd.none )

        _ ->
            ( model, Cmd.none )


dialView : Seconds -> Seconds -> Float -> Html Msg
dialView currentTime maxTime maxStrokeDasharray =
    let
        percent =
            1 * toFloat currentTime / toFloat maxTime

        strokeDasharray =
            maxStrokeDasharray - maxStrokeDasharray * percent

        colorToHtmlRgbString c =
            "rgb(" ++ String.fromInt c.r ++ ", " ++ String.fromInt c.g ++ ", " ++ String.fromInt c.b ++ ")"

        green =
            { r = 5, g = 236, b = 140 }

        orange =
            { r = 255, g = 127, b = 14 }

        red =
            { r = 255, g = 78, b = 77 }

        color =
            colorToHtmlRgbString <|
                let
                    relativePercent =
                        1 * (toFloat currentTime - toFloat maxTime / 2) / (toFloat maxTime / 2)
                in
                if percent > 0.5 then
                    { r = orange.r + (relativePercent * (green.r - orange.r)) |> round
                    , g = orange.g + (relativePercent * (green.g - orange.g)) |> round
                    , b = orange.b + (relativePercent * (green.b - orange.b)) |> round
                    }

                else
                    { r = red.r + ((1 + relativePercent) * (orange.r - red.r)) |> round
                    , g = red.g + ((1 + relativePercent) * (orange.g - red.g)) |> round
                    , b = red.b + ((1 + relativePercent) * (orange.b - red.b)) |> round
                    }
    in
    div [ class "dial-wrapper" ]
        [ p [ class "dial-time" ]
            [ text <| String.padLeft 2 '0' <| String.fromInt (currentTime // 60)
            , text ":"
            , text <| String.padLeft 2 '0' <| String.fromInt (modBy 60 currentTime)
            ]
        , p [ class "dial-label", style "color" color ] [ text "Focus" ]
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
                [ attribute "data-v-04292d65" ""
                , SvgAttr.version "1.2"
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
                    [ attribute "data-v-04292d65" ""
                    , SvgAttr.fill "none"
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
                    [ attribute "data-v-04292d65" ""
                    , SvgAttr.fill "none"
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
                    [ attribute "data-v-04292d65" ""
                    , SvgAttr.fill "var(--color-foreground)"
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


footerView : Html Msg
footerView =
    section [ class "container", class "footer" ]
        [ div [ class "round-wrapper" ]
            [ p [] [ text "1/4" ]
            , p [ class "text-button", title "Reset current round" ] [ text "Reset" ]
            ]
        , div [ class "icon-group", style "position" "absolute", style "right" "0px" ]
            [ div [ class "icon-wrapper", class "icon-wrapper--double--left", title "Skip the current round" ]
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
            , div [ class "icon-wrapper", class "icon-wrapper--double--right", title "Mute" ]
                [ svg
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
                        [ attribute "data-v-b9a0799a" ""
                        , SvgAttr.fill "var(--color-background-lightest)"
                        , SvgAttr.d "M0,3.9v4.1h2.7l3.4,3.4V0.5L2.7,3.9H0z M9.2,6c0-1.2-0.7-2.3-1.7-2.8v5.5C8.5,8.3,9.2,7.2,9.2,6z M7.5,0v1.4 c2,0.6,3.4,2.4,3.4,4.6s-1.4,4-3.4,4.6V12c2.7-0.6,4.8-3.1,4.8-6S10.3,0.6,7.5,0z"
                        ]
                        []
                    ]
                ]
            ]
        ]


timerView : Model -> Html Msg
timerView model =
    div [ class "timer-wrapper" ]
        [ dialView model.currentTime
            (case model.currentSessionType of
                Pomodoro ->
                    model.pomodoroDuration

                LongBreak ->
                    model.longBreakDuration

                ShortBreak ->
                    model.shortBreakDuration
            )
            model.strokeDasharray
        , playPauseView model.sessionStatus
        , footerView
        ]


navView : Html Msg
navView =
    nav [ class "titlebar" ]
        [ div [ title "Settings", class "icon-wrapper", class "icon-wrapper--titlebar", class "icon-wrapper--single" ]
            [ div [ class "menu-wrapper" ]
                [ div [ class "menu-line" ] []
                , div [ class "menu-line" ] []
                ]
            ]
        , h1 [ class "title" ] [ text "Pomodorolm" ]
        , div [ class "icon-group" ]
            [ div [ class "icon-wrapper icon-wrapper--titlebar icon-wrapper--double--left", style "padding-left" "18px" ]
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
                        [ attribute "data-v-9e10a67e" ""
                        , SvgAttr.fill "none"
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
                        [ attribute "data-v-9e10a67e" ""
                        , SvgAttr.fill "none"
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


view : Model -> Html Msg
view model =
    div [ id "app" ]
        [ navView
        , timerView model
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- PORTS


port playSound : String -> Cmd msg
