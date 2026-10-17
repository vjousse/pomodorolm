module Types exposing
    ( CurrentState
    , ResetType(..)
    , Setting(..)
    , SettingTab(..)
    , SettingType(..)
    )

import Color exposing (RGB)
import SessionStatus exposing (SessionStatus)
import SessionType exposing (SessionType)


type ResetType
    = CurrentRound
    | EntireSession


type alias CurrentState =
    { color : RGB
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
