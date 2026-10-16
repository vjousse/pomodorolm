module Msg exposing (Msg(..))

import Json exposing (ExternalMessage)
import SessionType exposing (SessionType)
import Themes exposing (Theme)
import Types exposing (ResetType, SettingTab, SettingType)


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
