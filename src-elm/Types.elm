module Types exposing (Config, ConfigAndThemes, CurrentState, Defaults, ElmMessage, ExternalMessage(..), NextRoundInfo, Notification, RustSession, RustState, Seconds, SessionStatus(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..))

import Themes exposing (Theme)


type alias Seconds =
    Int


type alias ElmMessage =
    { name : String }


type alias Config =
    { alwaysOnTop : Bool
    , autoStartBreakTimer : Bool
    , autoStartWorkTimer : Bool
    , desktopNotifications : Bool
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , theme : String
    , tickSoundsDuringBreak : Bool
    , tickSoundsDuringWork : Bool
    }


type alias ConfigAndThemes =
    { config : Config
    , themes : List Theme
    }


type alias CurrentState =
    { color : String, percentage : Float, paused : Bool }


type SessionType
    = Focus
    | ShortBreak
    | LongBreak


type SessionStatus
    = NotStarted
    | Paused
    | Running


type SettingTab
    = TimerTab
    | ThemeTab
    | SettingsTab
    | AboutTab


type Setting
    = AlwaysOnTop
    | AutoStartWorkTimer
    | AutoStartBreakTimer
    | TickSoundsDuringWork
    | TickSoundsDuringBreak
    | DesktopNotifications
    | MinimizeToTray
    | MinimizeToTrayOnClose


type alias Notification =
    { body : String
    , title : String
    , name : String
    , red : Int
    , green : Int
    , blue : Int
    }


type alias NextRoundInfo =
    { nextSessionType : SessionType
    , htmlIdOfAudioToPlay : String
    , nextRoundNumber : Int
    , nextTime : Seconds
    , notification : Notification
    }


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
    }


type SettingType
    = FocusTime
    | LongBreakTime
    | Rounds
    | ShortBreakTime


type alias RustSession =
    { currentTime : Int
    , label : Maybe String
    , sessionType : SessionType
    , status : SessionStatus
    }


type alias RustState =
    { currentSession : RustSession
    }


type ExternalMessage
    = RustStateMsg RustState
    | RustConfigAndThemesMsg ConfigAndThemes
