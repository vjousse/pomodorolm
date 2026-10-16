module Config exposing (Config)

import Seconds exposing (Seconds)
import SessionType exposing (SessionType)


type alias Config =
    { alwaysOnTop : Bool
    , autoQuit : Maybe SessionType
    , autoStartBreakTimer : Bool
    , autoStartOnAppStartup : Bool
    , autoStartWorkTimer : Bool
    , defaultFocusLabel : String
    , defaultLongBreakLabel : String
    , defaultShortBreakLabel : String
    , desktopNotifications : Bool
    , focusAudio : Maybe String
    , focusDuration : Seconds
    , longBreakAudio : Maybe String
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , maxSessionDuration : Seconds
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , muted : Bool
    , shortBreakAudio : Maybe String
    , shortBreakDuration : Seconds
    , startMinimized : Bool
    , systemStartupAutoStart : Bool
    , theme : String
    , tickSoundsDuringBreak : Bool
    , tickSoundsDuringWork : Bool
    , volume : Maybe Int
    }
