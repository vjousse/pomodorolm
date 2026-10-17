-- Initial code is courtesy of to https://package.elm-lang.org/packages/juliusl/elm-ui-hexcolor/latest/Element-HexColor


module Color exposing (RGB(..), ThemeColors, colorForSessionType, computeCurrentColor, encode, fromCSSHex, toCSSHex, toHtmlRgbString)

import Hex
import Json.Encode as Encode
import Seconds exposing (Seconds)
import SessionType exposing (SessionType(..))


type RGB
    = RGB Int Int Int


type alias ThemeColors =
    { accent : RGB
    , background : RGB
    , backgroundLight : RGB
    , backgroundLightest : RGB
    , focusRound : RGB
    , focusRoundEnd : RGB
    , focusRoundMiddle : RGB
    , foreground : RGB
    , foregroundDarker : RGB
    , foregroundDarkest : RGB
    , longRound : RGB
    , shortRound : RGB
    }


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


fromCSSHex : String -> RGB
fromCSSHex hexcode =
    RGB (Hex.fromString (String.slice 1 3 hexcode) |> Result.withDefault 0)
        (Hex.fromString (String.slice 3 5 hexcode) |> Result.withDefault 0)
        (Hex.fromString (String.slice 5 7 hexcode) |> Result.withDefault 0)


toCSSHex : RGB -> String
toCSSHex (RGB r g b) =
    "#" ++ toStringWithZeroPadding r ++ toStringWithZeroPadding g ++ toStringWithZeroPadding b


toHtmlRgbString : RGB -> String
toHtmlRgbString (RGB r g b) =
    "rgb(" ++ String.fromInt r ++ ", " ++ String.fromInt g ++ ", " ++ String.fromInt b ++ ")"


colorForSessionType : SessionType -> ThemeColors -> RGB
colorForSessionType sessionType colors =
    case sessionType of
        Focus ->
            colors.focusRound

        ShortBreak ->
            colors.shortRound

        LongBreak ->
            colors.longRound


computeCurrentColor : Seconds -> Seconds -> SessionType -> ThemeColors -> RGB
computeCurrentColor currentTime maxTime sessionType colors =
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
                    colors.focusRoundMiddle
            in
            if remainingPercent > 0.5 then
                let
                    (RGB startRed startGreen startBlue) =
                        colors.focusRound
                in
                RGB
                    (toFloat middleRed + (relativePercent * toFloat (startRed - middleRed)) |> round)
                    (toFloat middleGreen + (relativePercent * toFloat (startGreen - middleGreen)) |> round)
                    (toFloat middleBlue + (relativePercent * toFloat (startBlue - middleBlue)) |> round)

            else
                let
                    (RGB endRed endGreen endBlue) =
                        colors.focusRoundEnd
                in
                RGB (toFloat endRed + ((1 + relativePercent) * toFloat (middleRed - endRed)) |> round)
                    (toFloat endGreen + ((1 + relativePercent) * toFloat (middleGreen - endGreen)) |> round)
                    (toFloat endBlue + ((1 + relativePercent) * toFloat (middleBlue - endBlue)) |> round)

        s ->
            colorForSessionType s colors


encode : RGB -> Encode.Value
encode color =
    Encode.string (toCSSHex color)
