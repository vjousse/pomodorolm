-- Initial code is courtesy of to https://package.elm-lang.org/packages/juliusl/elm-ui-hexcolor/latest/Element-HexColor


module ColorHelper exposing (RGB(..), fromCSSHexToRGB, fromRGBToCSSHex)

import Bitwise
import Dict exposing (Dict)
import Hex
import List


type RGB
    = RGB Int Int Int


fromCSSHexToRGB : String -> RGB
fromCSSHexToRGB hexcode =
    RGB (getRed hexcode) (getGreen hexcode) (getBlue hexcode)


fromRGBToCSSHex : RGB -> String
fromRGBToCSSHex (RGB r g b) =
    "#" ++ Hex.toString r ++ Hex.toString g ++ Hex.toString b


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
