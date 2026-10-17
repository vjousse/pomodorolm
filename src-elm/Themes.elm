module Themes exposing (Theme)

import ThemeColors exposing (ThemeColors)


type alias Theme =
    { colors : ThemeColors
    , name : String
    }
