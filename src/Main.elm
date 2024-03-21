module Main exposing (..)

import Browser
import Html exposing (Html, div, h1, nav, text)
import Html.Attributes exposing (attribute, class, id, style, title)
import Svg exposing (svg)
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


view : Model -> Html Msg
view _ =
    div [ id "app" ]
        [ nav [ class "titlebar" ]
            [ div [ title "Settings", class "icon-wrapper", class "icon-wrapper--titlebar", class "icon-wrapper--single", style "position" "absolute" ]
                [ div [ class "menu-wrapper" ]
                    [ div [ class "menu-line" ] []
                    , div [ class "menu-line" ] []
                    ]
                ]
            , h1 [ class "title" ] [ text "Pomodorolm" ]
            , div [ class "icon-group", style "position" "absolute", style "top" "0", style "right" "0" ]
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
        ]
