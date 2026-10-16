module Types exposing
    ( Config
    , CurrentState
    , PomodoroSession
    , PomodoroState
    , ResetType(..)
    , Setting(..)
    , SettingTab(..)
    , SettingType(..)
    )

import Seconds exposing (Seconds)
import SessionStatus exposing (SessionStatus)
import SessionType exposing (SessionType)


type ResetType
    = CurrentRound
    | EntireSession


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


type alias CurrentState =
    { color : String
    , percentage : Float
    , paused : Bool
    , sessionStatus : SessionStatus
    }


type SettingTab
    = TimerTab
    | ThemeTab
    | SettingsTab
    | SoundsTab
    | TextTab
    | AboutTab


type Setting
    = AlwaysOnTop
    | AutoStartBreakTimer
    | AutoStartOnAppStartup
    | AutoStartWorkTimer
    | DesktopNotifications
    | MinimizeToTray
    | MinimizeToTrayOnClose
    | StartMinimized
    | SystemStartupAutoStart
    | TickSoundsDuringWork
    | TickSoundsDuringBreak


type SettingType
    = AutoQuit String
    | FocusTime String
    | Label SessionType String
    | LongBreakTime String
    | MaxSessionDuration String
    | Rounds String
    | SaveMaxSessionDuration
    | ShortBreakTime String
    | Toggle Setting


type alias PomodoroSession =
    { currentTime : Seconds
    , label : Maybe String
    , sessionType : SessionType
    , status : SessionStatus
    }


type alias PomodoroState =
    { currentSession : PomodoroSession
    , currentWorkRoundNumber : Int
    }
