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
    | SetVolumeBarVisibility Bool
    | ProcessExternalMessage ExternalMessage
    | MinimizeWindow
    | NoOp
    | Reset ResetType
    | ResetSettings
    | ResetAudioFile SessionType
    | SkipCurrentRound
    | ToggleDrawer
    | ToggleMute
    | TogglePlayStatus
    | UpdateLabel SessionType String
    | UpdateSetting SettingType
    | UpdateVolume String
