import "../main.css";

import { Elm } from "../src-elm/Main.elm";

import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";

import { attachConsole } from "@tauri-apps/plugin-log";
import { open } from "@tauri-apps/plugin-dialog";
import { getVersion } from "@tauri-apps/api/app";

// Display logs in the webview inspector
attachConsole();

declare global {
  interface Window {
    __TAURI_INTERNALS__: any;
  }
}

type ElmState = {
  color: string;
  percentage: number;
  paused: boolean;
};

type Message = {
  name: string;
  value: string;
};

type Notification = {
  body: string;
  title: string;
  name: string;
  red: number;
  green: number;
  blue: number;
};

type RustThemeColors = {
  long_round: string;
  short_round: string;
  focus_round: string;
  focus_roundMiddle: string;
  focus_roundEnd: string;
  background: string;
  background_light: string;
  background_lightest: string;
  foreground: string;
  foreground_darker: string;
  foreground_darkest: string;
  accent: string;
};
type ThemeColors = {
  longRound: string;
  shortRound: string;
  focusRound: string;
  focusRoundMiddle: string;
  focusRoundEnd: string;
  background: string;
  backgroundLight: string;
  backgroundLightest: string;
  foreground: string;
  foregroundDarker: string;
  foregroundDarkest: string;
  accent: string;
};

type ElmConfig = {
  alwaysOnTop: boolean;
  autoStartWorkTimer: boolean;
  autoStartBreakTimer: boolean;
  desktopNotifications: boolean;
  focusAudio: string | null;
  focusDuration: number;
  longBreakAudio: string | null;
  longBreakDuration: number;
  maxRoundNumber: number;
  minimizeToTray: boolean;
  minimizeToTrayOnClose: boolean;
  muted: boolean;
  shortBreakAudio: string | null;
  shortBreakDuration: number;
  theme: string;
  tickSoundsDuringWork: boolean;
  tickSoundsDuringBreak: boolean;
};

type RustConfig = {
  always_on_top: boolean;
  auto_start_work_timer: boolean;
  auto_start_break_timer: boolean;
  desktop_notifications: boolean;
  focus_audio: string | null;
  focus_duration: number;
  long_break_audio: string | null;
  long_break_duration: number;
  max_round_number: number;
  minimize_to_tray: boolean;
  minimize_to_tray_on_close: boolean;
  muted: boolean;
  short_break_audio: string | null;
  short_break_duration: number;
  theme: string;
  tick_sounds_during_work: boolean;
  tick_sounds_during_break: boolean;
};

const root = document.querySelector("#app div");

let rustConfig: RustConfig = {
  always_on_top: true,
  auto_start_work_timer: true,
  auto_start_break_timer: true,
  desktop_notifications: true,
  focus_audio: null,
  focus_duration: 1500,
  long_break_audio: null,
  long_break_duration: 1200,
  max_round_number: 4,
  minimize_to_tray: true,
  minimize_to_tray_on_close: true,
  muted: false,
  short_break_audio: null,
  short_break_duration: 300,
  theme: "pomodorolm",
  tick_sounds_during_work: true,
  tick_sounds_during_break: true,
};

let app;

app = Elm.Main.init({
  node: root,
  flags: {
    alwaysOnTop: rustConfig.always_on_top,
    appVersion: await getAppVersion(),
    autoStartWorkTimer: rustConfig.auto_start_work_timer,
    autoStartBreakTimer: rustConfig.auto_start_break_timer,
    desktopNotifications: rustConfig.desktop_notifications,
    focusAudio: rustConfig.focus_duration,
    focusDuration: rustConfig.focus_duration,
    longBreakDuration: rustConfig.long_break_duration,
    maxRoundNumber: rustConfig.max_round_number,
    minimizeToTray: rustConfig.minimize_to_tray,
    minimizeToTrayOnClose: rustConfig.minimize_to_tray_on_close,
    muted: rustConfig.muted,
    shortBreakDuration: rustConfig.short_break_duration,
    theme: rustConfig.theme,
    tickSoundsDuringWork: rustConfig.tick_sounds_during_work,
    tickSoundsDuringBreak: rustConfig.tick_sounds_during_break,
  },
});

app.ports.playSound.subscribe(function (soundElementId: string) {
  invoke("play_sound_command", { soundId: soundElementId });
});

app.ports.hideWindow.subscribe(function () {
  invoke("hide_window");
});

app.ports.minimizeWindow.subscribe(function () {
  invoke("minimize_window");
});

app.ports.closeWindow.subscribe(function () {
  invoke("close_window");
});

app.ports.getConfigFromRust.subscribe(function () {
  invoke("load_config_and_themes").then((config_and_themes) => {
    const [config, themes] = config_and_themes as [
      RustConfig,
      Array<RustThemeColors>
    ];
    app.ports.sendMessageToElm.send({ config, themes });
  });
});

app.ports.notify.subscribe(function (notification: Notification) {
  invoke("notify", { notification: notification });
});

app.ports.sendMessageFromElm.subscribe(async function (message: Message) {
  console.log(`Sending message from Elm ${message}`);
  switch (message.name) {
    case "choose_sound_file":
      const file = await open({
        multiple: false,
        directory: false,
        filters: [
          {
            name: "audio (mp3, wav, ogg, flac)",
            extensions: ["mp3", "wav", "ogg", "flac"],
          },
        ],
      });
      console.log(file);
      app.ports.sendMessageToElm.send({
        session_type: message.value,
        file_path: file,
      });
      break;

    default:
      invoke("handle_external_message", message).then((newState) => {
        console.log(newState);
        app.ports.sendMessageToElm.send(newState);
      });
  }
});

app.ports.updateConfig.subscribe(function (config: ElmConfig) {
  invoke("update_config", {
    config: {
      always_on_top: config.alwaysOnTop,
      auto_start_work_timer: config.autoStartWorkTimer,
      auto_start_break_timer: config.autoStartBreakTimer,
      desktop_notifications: config.desktopNotifications,
      focus_audio: config.focusAudio,
      focus_duration: config.focusDuration,
      long_break_audio: config.longBreakAudio,
      long_break_duration: config.longBreakDuration,
      max_round_number: config.maxRoundNumber,
      minimize_to_tray: config.minimizeToTray,
      minimize_to_tray_on_close: config.minimizeToTrayOnClose,
      muted: config.muted,
      short_break_audio: config.shortBreakAudio,
      short_break_duration: config.shortBreakDuration,
      theme: config.theme,
      tick_sounds_during_work: config.tickSoundsDuringWork,
      tick_sounds_during_break: config.tickSoundsDuringBreak,
    },
  });
});

app.ports.updateCurrentState.subscribe(function (state: ElmState) {
  invoke("change_icon", {
    red: hexToRgb(state.color)?.r,
    green: hexToRgb(state.color)?.g,
    blue: hexToRgb(state.color)?.b,
    fillPercentage: state.percentage,
    paused: state.paused,
  });
});

app.ports.updateSessionStatus.subscribe(function (status: String) {
  invoke("update_session_status", { status });
});

app.ports.setThemeColors.subscribe(function (themeColors: ThemeColors) {
  let mainHtmlElement = document.documentElement;
  mainHtmlElement.style.setProperty(
    "--color-long-round",
    themeColors.longRound
  );
  mainHtmlElement.style.setProperty(
    "--color-short-round",
    themeColors.shortRound
  );
  mainHtmlElement.style.setProperty(
    "--color-focus-round",
    themeColors.focusRound
  );
  mainHtmlElement.style.setProperty(
    "--color-background",
    themeColors.background
  );
  mainHtmlElement.style.setProperty(
    "--color-background-light",
    themeColors.backgroundLight
  );
  mainHtmlElement.style.setProperty(
    "--color-background-lightest",
    themeColors.backgroundLightest
  );
  mainHtmlElement.style.setProperty(
    "--color-foreground",
    themeColors.foreground
  );
  mainHtmlElement.style.setProperty(
    "--color-foreground-darker",
    themeColors.foregroundDarker
  );
  mainHtmlElement.style.setProperty(
    "--color-foreground-darkest",
    themeColors.foregroundDarkest
  );
  mainHtmlElement.style.setProperty("--color-accent", themeColors.accent);
});

await listen("tick-event", () => {
  app.ports.tick.send(null);
});

await listen("external-message", (message) => {
  app.ports.sendMessageToElm.send(message.payload);
});

await listen("toggle-play", () => {
  app.ports.togglePlay.send(null);
});

await listen("skip", () => {
  app.ports.skip.send(null);
});

function hexToRgb(hex: string) {
  var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
}

async function getAppVersion() {
  if (window.__TAURI_INTERNALS__ === undefined) {
    return "unknown";
  } else {
    return await getVersion();
  }
}
