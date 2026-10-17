module Themes exposing (Theme, pomodorolmTheme)

import ThemeColors exposing (ThemeColors)


type alias Theme =
    { colors : ThemeColors
    , name : String
    }


pomodorolmTheme : Theme
pomodorolmTheme =
    { colors =
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
    , name = "Pomodorolm"
    }
