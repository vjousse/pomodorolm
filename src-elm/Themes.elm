module Themes exposing (Theme)

import Color exposing (ThemeColors)


type alias Theme =
    { colors : ThemeColors
    , name : String
    }
