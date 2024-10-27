module Types exposing (Config, ConfigAndThemes, CurrentState, Defaults, ElmMessage, ExternalMessage(..), Model, Msg(..), Notification, RGB(..), RustSession, RustState, Seconds, SessionStatus(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..))

import ListWithCurrent exposing (ListWithCurrent)
import Themes exposing (Theme)


type RGB
    = RGB Int Int Int


type alias Model =
    { appVersion : String
    , config : Config
    , currentColor : RGB
    , currentState : CurrentState
    , drawerOpen : Bool
    , pomodoroState : Maybe RustState
    , settingTab : SettingTab
    , strokeDasharray : Float
    , theme : Theme
    , themes : ListWithCurrent Theme
    , volume : Float
    , volumeSliderHidden : Bool
    }


type Msg
    = CloseWindow
    | ChangeSettingTab SettingTab
    | ChangeSettingConfig Setting
    | ChangeTheme Theme
    | HideVolumeBar
    | ProcessExternalMessage ExternalMessage
    | MinimizeWindow
    | NoOp
    | Reset
    | ResetSettings
    | ResetShortBreakAudioFile
    | ShortBreakAudioFileRequested
    | SkipCurrentRound
    | ToggleDrawer
    | ToggleMute
    | TogglePlayStatus
    | UpdateSetting SettingType String
    | UpdateVolume String


type alias Seconds =
    Int


type alias ElmMessage =
    { name : String }


type alias Config =
    { alwaysOnTop : Bool
    , autoStartBreakTimer : Bool
    , autoStartWorkTimer : Bool
    , desktopNotifications : Bool
    , focusAudio : Maybe String
    , longBreakAudio : Maybe String
    , longBreakDuration : Seconds
    , maxRoundNumber : Int
    , minimizeToTray : Bool
    , minimizeToTrayOnClose : Bool
    , muted : Bool
    , pomodoroDuration : Seconds
    , shortBreakAudio : Maybe String
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


type alias Notification =
    { body : String
    , title : String
    , name : String
    , red : Int
    , green : Int
    , blue : Int
    }


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
    { currentTime : Seconds
    , label : Maybe String
    , sessionType : SessionType
    , status : SessionStatus
    }


type alias RustState =
    { currentSession : RustSession
    , currentWorkRoundNumber : Int
    }


type ExternalMessage
    = RustStateMsg RustState
    | RustConfigAndThemesMsg ConfigAndThemes
    | SoundFilePath SessionType String
