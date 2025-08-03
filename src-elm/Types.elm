module Types exposing (Config, CurrentState, Defaults, ElmMessage, ExternalMessage(..), InitData, Model, Msg(..), Notification, PomodoroSession, PomodoroState, RGB(..), Seconds, SessionStatus(..), SessionType(..), Setting(..), SettingTab(..), SettingType(..), sessionTypeToString)

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
    , focusLabel : String
    , longBreakLabel : String
    , pomodoroState : Maybe PomodoroState
    , settingTab : SettingTab
    , shortBreakLabel : String
    , strokeDasharray : Float
    , theme : Theme
    , themes : ListWithCurrent Theme
    , volume : Float
    , volumeSliderHidden : Bool
    }


type Msg
    = AudioFileRequested SessionType
    | CloseWindow
    | ChangeSettingTab SettingTab
    | ChangeTheme Theme
    | HideVolumeBar
    | ProcessExternalMessage ExternalMessage
    | MinimizeWindow
    | NoOp
    | Reset
    | ResetSettings
    | ResetAudioFile SessionType
    | SkipCurrentRound
    | ToggleDrawer
    | ToggleMute
    | TogglePlayStatus
    | UpdateLabel SessionType String
    | UpdateSetting SettingType
    | UpdateVolume String


type alias Seconds =
    Int


type alias ElmMessage =
    { name : String
    , value : Maybe String
    }


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
    }


type alias InitData =
    { config : Config
    , pomodoroState : PomodoroState
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


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
    }


type SettingType
    = FocusTime String
    | Label SessionType String
    | LongBreakTime String
    | Rounds String
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


type ExternalMessage
    = RustStateMsg PomodoroState
    | InitDataMsg InitData
    | SoundFilePath SessionType String


sessionTypeToString : SessionType -> String
sessionTypeToString sessionType =
    case sessionType of
        Focus ->
            "focus"

        ShortBreak ->
            "shortbreak"

        LongBreak ->
            "longbreak"
