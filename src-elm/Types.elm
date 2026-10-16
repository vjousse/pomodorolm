module Types exposing
    ( Config
    , CurrentState
    , Defaults
    , ExternalMessage(..)
    , InitData
    , Model
    , Msg(..)
    , PomodoroSession
    , PomodoroState
    , ResetType(..)
    , Setting(..)
    , SettingTab(..)
    , SettingType(..)
    , SoundMessageValue
    )

import ColorHelper exposing (RGB)
import ListWithCurrent exposing (ListWithCurrent)
import Seconds exposing (Seconds)
import SessionStatus exposing (SessionStatus)
import SessionType exposing (SessionType)
import Themes exposing (Theme)


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
    | Reset ResetType
    | ResetSettings
    | ResetAudioFile SessionType
    | SkipCurrentRound
    | ShowVolumeBar
    | ToggleDrawer
    | ToggleMute
    | TogglePlayStatus
    | UpdateLabel SessionType String
    | UpdateSetting SettingType
    | UpdateVolume String


type ResetType
    = CurrentRound
    | EntireSession


type alias SoundMessageValue =
    { soundId : String
    , quitAfterPlay : Bool
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


type alias InitData =
    { config : Config
    , pomodoroState : PomodoroState
    , themes : List Theme
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


type alias Defaults =
    { longBreakDuration : Seconds
    , pomodoroDuration : Seconds
    , shortBreakDuration : Seconds
    , maxRoundNumber : Int
    }


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


type ExternalMessage
    = RustStateMsg PomodoroState
    | InitDataMsg InitData
    | SoundFilePath SessionType String
