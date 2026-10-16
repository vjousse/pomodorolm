-- Initial code is courtesy of to https://package.elm-lang.org/packages/juliusl/elm-ui-hexcolor/latest/Element-HexColor


module ColorHelper exposing (colorForSessionType, computeCurrentColor, fromCSSHexToRGB, fromRGBToCSSHex)

import Hex
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
    RGB (Hex.fromString (String.slice 1 3 hexcode) |> Result.withDefault 0)
        (Hex.fromString (String.slice 3 5 hexcode) |> Result.withDefault 0)
        (Hex.fromString (String.slice 5 7 hexcode) |> Result.withDefault 0)


fromRGBToCSSHex : RGB -> String
fromRGBToCSSHex (RGB r g b) =
    "#" ++ toStringWithZeroPadding r ++ toStringWithZeroPadding g ++ toStringWithZeroPadding b


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

                (RGB middleRed middleGreen middleBlue) =
                    fromCSSHexToRGB theme.colors.focusRoundMiddle
            in
            if remainingPercent > 0.5 then
                let
                    (RGB startRed startGreen startBlue) =
                        fromCSSHexToRGB theme.colors.focusRound
                in
                RGB
                    (toFloat middleRed + (relativePercent * toFloat (startRed - middleRed)) |> round)
                    (toFloat middleGreen + (relativePercent * toFloat (startGreen - middleGreen)) |> round)
                    (toFloat middleBlue + (relativePercent * toFloat (startBlue - middleBlue)) |> round)

            else
                let
                    (RGB endRed endGreen endBlue) =
                        fromCSSHexToRGB theme.colors.focusRoundEnd
                in
                RGB (toFloat endRed + ((1 + relativePercent) * toFloat (middleRed - endRed)) |> round)
                    (toFloat endGreen + ((1 + relativePercent) * toFloat (middleGreen - endGreen)) |> round)
                    (toFloat endBlue + ((1 + relativePercent) * toFloat (middleBlue - endBlue)) |> round)

        s ->
            colorForSessionType s theme
