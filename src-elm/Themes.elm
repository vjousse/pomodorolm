module Themes exposing (Theme)

import ColorHelper exposing (ThemeColors)


type alias Theme =
    { colors : ThemeColors
    , name : String
    }
