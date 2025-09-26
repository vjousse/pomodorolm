-- Initial code is courtesy of to https://package.elm-lang.org/packages/juliusl/elm-ui-hexcolor/latest/Element-HexColor


module ColorHelper exposing (colorForSessionType, computeCurrentColor, fromCSSHexToRGB, fromRGBToCSSHex)

import Bitwise
import Dict exposing (Dict)
import Hex
import List
import Themes exposing (Theme)
import Types exposing (RGB(..), Seconds, SessionType(..))


toStringWithZeroPadding : Int -> String
toStringWithZeroPadding num =
    let
        stringValue =
            Hex.toString num
    in
    if String.length stringValue < 2 then
        "0" ++ stringValue

    else
        stringValue


fromCSSHexToRGB : String -> RGB
fromCSSHexToRGB hexcode =
    RGB (getRed hexcode) (getGreen hexcode) (getBlue hexcode)


fromRGBToCSSHex : RGB -> String
fromRGBToCSSHex (RGB r g b) =
    "#" ++ toStringWithZeroPadding r ++ toStringWithZeroPadding g ++ toStringWithZeroPadding b


getRed : String -> Int
getRed hexcode =
    fromList (List.take 2 (fromCSSString hexcode))


getGreen : String -> Int
getGreen hexcode =
    fromList (List.take 2 (List.drop 2 (fromCSSString hexcode)))


getBlue : String -> Int
getBlue hexcode =
    fromList (List.take 2 (List.drop 4 (fromCSSString hexcode)))


fromCSSString : String -> List Char
fromCSSString hexcode =
    List.drop 1 (String.toList hexcode)


fromList : List Char -> Int
fromList chars =
    List.sum (List.indexedMap (\i v -> Bitwise.shiftLeftBy (i * 4) v) (List.reverse (List.map fromChar chars)))


fromChar : Char -> Int
fromChar ch =
    case Dict.get ch hexmap of
        Just v ->
            v

        Nothing ->
            0


hexmap : Dict Char Int
hexmap =
    Dict.fromList
        [ ( '0', 0 )
        , ( '1', 1 )
        , ( '2', 2 )
        , ( '3', 3 )
        , ( '4', 4 )
        , ( '5', 5 )
        , ( '6', 6 )
        , ( '7', 7 )
        , ( '8', 8 )
        , ( '9', 9 )
        , ( 'A', 10 )
        , ( 'B', 11 )
        , ( 'C', 12 )
        , ( 'D', 13 )
        , ( 'E', 14 )
        , ( 'F', 15 )
        , ( 'a', 10 )
        , ( 'b', 11 )
        , ( 'c', 12 )
        , ( 'd', 13 )
        , ( 'e', 14 )
        , ( 'f', 15 )
        ]


colorForSessionType : SessionType -> Theme -> RGB
colorForSessionType sessionType theme =
    case sessionType of
        Focus ->
            fromCSSHexToRGB <| theme.colors.focusRound

        ShortBreak ->
            fromCSSHexToRGB <| theme.colors.shortRound

        LongBreak ->
            fromCSSHexToRGB <| theme.colors.longRound


computeCurrentColor : Seconds -> Seconds -> SessionType -> Theme -> RGB
computeCurrentColor currentTime maxTime sessionType theme =
    case sessionType of
        Focus ->
            let
                remainingPercent =
                    if maxTime /= 0 then
                        toFloat (maxTime - currentTime) / toFloat maxTime

                    else
                        1

                relativePercent =
                    if maxTime /= 0 then
                        (toFloat (maxTime - currentTime) - toFloat maxTime / 2) / (toFloat maxTime / 2)

                    else
                        1

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
            if remainingPercent > 0.5 then
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
