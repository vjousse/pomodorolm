module Themes exposing (RGBColor(..), Theme(..), ThemeColors, allThemes, getThemeColors, getThemeName, nord, pomotroid, themeFromString)


type RGBColor
    = RGB Int Int Int
    | RGBA Int Int Int Float


type Theme
    = Nord
    | Pomotroid
    | TokyoNightStorm


type alias ThemeColors =
    { longRound : String
    , shortRound : String
    , focusRound : String
    , focusRoundMiddle : String
    , focusRoundEnd : String
    , background : String
    , backgroundLight : String
    , backgroundLightest : String
    , foreground : String
    , foregroundDarker : String
    , foregroundDarkest : String
    , accent : String
    }


getThemeColors : Theme -> ThemeColors
getThemeColors theme =
    case theme of
        Nord ->
            nord

        Pomotroid ->
            pomotroid

        TokyoNightStorm ->
            tokyoNightStorm


getThemeName : Theme -> String
getThemeName theme =
    case theme of
        Nord ->
            "Nord"

        Pomotroid ->
            "Pomotroid"

        TokyoNightStorm ->
            "Tokyo Night Storm"


themeFromString : String -> Theme
themeFromString string =
    case String.toLower string of
        "nord" ->
            Nord

        "pomotroid" ->
            Pomotroid

        "tokyo night storm" ->
            TokyoNightStorm

        _ ->
            Pomotroid


allThemes : List Theme
allThemes =
    next [] |> List.reverse


next : List Theme -> List Theme
next list =
    case List.head list of
        Nothing ->
            Nord :: list |> next

        Just Nord ->
            Pomotroid :: list |> next

        Just Pomotroid ->
            TokyoNightStorm :: list |> next

        Just TokyoNightStorm ->
            list


pomotroid : ThemeColors
pomotroid =
    { longRound = "#0bbddb"
    , shortRound = "#ff4e4d"
    , focusRound = "#05ec8c"
    , focusRoundMiddle = "#ff7f0e"
    , focusRoundEnd = "#ff4e4d"
    , background = "#2f384b"
    , backgroundLight = "#3d4457"
    , backgroundLightest = "#858c99"
    , foreground = "#f6f2eb"
    , foregroundDarker = "#c0c9da"
    , foregroundDarkest = "#dbe1ef"
    , accent = "#05ec8c"
    }


nord : ThemeColors
nord =
    { longRound = "#5e81ac"
    , shortRound = "#8fbcbb"
    , focusRound = "#b48ead"
    , focusRoundMiddle = "#a2a5b4"
    , focusRoundEnd = "#8fbcbb"
    , background = "#2e3440"
    , backgroundLight = "#3b4252"
    , backgroundLightest = "#616e88"
    , foreground = "#d8dee9"
    , foregroundDarker = "#8fbcbb"
    , foregroundDarkest = "#88c0d0"
    , accent = "#a3be8c"
    }


tokyoNightStorm : ThemeColors
tokyoNightStorm =
    { longRound = "#7AA2F7"
    , shortRound = "#ff757f"
    , focusRound = "#4fd6be"
    , focusRoundMiddle = "#ff9e64"
    , focusRoundEnd = "#ff757f"
    , background = "#24283b"
    , backgroundLight = "#1b1e2e"
    , backgroundLightest = "#9AA5CE"
    , foreground = "#c0caf5"
    , foregroundDarker = "#9AA5CE"
    , foregroundDarkest = "#89DDFF"
    , accent = "#9D7CD8"
    }
