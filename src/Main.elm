module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, nav, p, section, text)
import Html.Attributes exposing (attribute, class, id, style, title)
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }


type alias Model =
    Int


init : Model
init =
    0


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


timerView : Html Msg
timerView =
    div [ class "timer-wrapper" ]
        [ div [ class "dial-wrapper" ]
            [ p [ class "dial-time" ] [ text "25:00" ]
            , p [ class "dial-label" ] [ text "Focus" ]
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
                , SvgAttr.class "dial-fill dial-fill--work"
                ]
                [ path
                    [ SvgAttr.fill "none"
                    , SvgAttr.strokeWidth "10"
                    , SvgAttr.strokeLinecap "round"
                    , SvgAttr.strokeMiterlimit "10"
                    , SvgAttr.d "M115,5c60.8,0,110,49.2,110,110s-49.2,110-110,110S5,175.8,5,115S54.2,5,115,5"
                    , SvgAttr.strokeDasharray "691.3321533203125"
                    , SvgAttr.style "stroke-dashoffset: 0px;"
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
        , section [ class "container", class "button-wrapper" ]
            [ div [ class "button" ]
                [ div [ class "button-icon-wrapper" ]
                    [ svg
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
                    ]
                ]
            ]
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
view _ =
    div [ id "app" ]
        [ navView
        , timerView
        ]
