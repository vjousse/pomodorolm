module Themes exposing (RGBColor(..), Theme(..), ThemeColors, getThemeColors, nord, pomotroid)


type RGBColor
    = RGB Int Int Int
    | RGBA Int Int Int Float


type Theme
    = Nord ThemeColors
    | Pomotroid ThemeColors


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
        Nord t ->
            t

        Pomotroid t ->
            t


pomotroid : ThemeColors
pomotroid =
    { longRound = "#0bbddb"
    , shortRound = "#05ec8c"
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
    , focusRoundMiddle = "#ff7f0e"
    , focusRoundEnd = "#ff4e4d"
    , background = "#2e3440"
    , backgroundLight = "#3b4252"
    , backgroundLightest = "#616e88"
    , foreground = "#d8dee9"
    , foregroundDarker = "#8fbcbb"
    , foregroundDarkest = "#88c0d0"
    , accent = "#a3be8c"
    }
