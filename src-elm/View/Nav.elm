module View.Nav exposing (navView)

import Html exposing (Html, a, div, h1, nav, text)
import Html.Attributes exposing (attribute, class, href, style, target, title)
import Html.Events exposing (onClick)
import Msg exposing (Msg(..))
import Svg exposing (svg)
import Svg.Attributes as SvgAttr
import Types exposing (Model)


navView : Model -> Html Msg
navView model =
    nav [ class "titlebar" ]
        [ div [ class "icon-group" ]
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
            , div [ class "icon-wrapper icon-wrapper--titlebar" ]
                [ a
                    [ target "_blank"
                    , style "padding-top" "1vw"
                    , href "https://ko-fi.com/vjousse"
                    , title "Support development"
                    ]
                    [ svg
                        [ SvgAttr.width "6vw"
                        , SvgAttr.height "6vw"
                        , SvgAttr.viewBox "0 0 24 24"
                        , SvgAttr.version "1.1"
                        ]
                        [ Svg.g
                            [ SvgAttr.transform "translate(0 -1028.4)"
                            ]
                            [ Svg.path
                                [ SvgAttr.d "m7 1031.4c-1.5355 0-3.0784 0.5-4.25 1.7-2.3431 2.4-2.2788 6.1 0 8.5l9.25 9.8 9.25-9.8c2.279-2.4 2.343-6.1 0-8.5-2.343-2.3-6.157-2.3-8.5 0l-0.75 0.8-0.75-0.8c-1.172-1.2-2.7145-1.7-4.25-1.7z"
                                , SvgAttr.fill "#e74c3c"
                                ]
                                []
                            ]
                        ]
                    ]
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
