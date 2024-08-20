module Themes exposing (RGBColor(..), Theme, ThemeColors, pomodorolmTheme)


type RGBColor
    = RGB Int Int Int
    | RGBA Int Int Int Float


type alias Theme =
    { colors : ThemeColors
    , name : String
    }


type alias ThemeColors =
    { accent : String
    , background : String
    , backgroundLight : String
    , backgroundLightest : String
    , focusRound : String
    , focusRoundEnd : String
    , focusRoundMiddle : String
    , foreground : String
    , foregroundDarker : String
    , foregroundDarkest : String
    , longRound : String
    , shortRound : String
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
