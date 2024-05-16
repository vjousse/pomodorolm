import "../main.css";

import { Elm } from "../src-elm/Main.elm";

import { invoke } from "@tauri-apps/api";
import { listen } from "@tauri-apps/api/event";

import { attachConsole, info } from "tauri-plugin-log-api";

// Display logs in the webview inspector
attachConsole();

type Color = {
  r: number;
  g: number;
  b: number;
};

type ElmState = {
  color: Color;
  percentage: number;
  paused: boolean;
  playTick: boolean;
};

type Notification = {
  body: string;
  title: string;
  name: string;
  red: number;
  green: number;
  blue: number;
};

type ElmConfig = {
  alwaysOnTop: boolean;
  autoStartWorkTimer: boolean;
  autoStartBreakTimer: boolean;
  desktopNotifications: boolean;
  longBreakDuration: number;
  maxRoundNumber: number;
  minimizeToTray: boolean;
  minimizeToTrayOnClose: boolean;
  pomodoroDuration: number;
  shortBreakDuration: number;
  tickSoundsDuringWork: boolean;
  tickSoundsDuringBreak: boolean;
};

type RustConfig = {
  always_on_top: boolean;
  auto_start_work_timer: boolean;
  auto_start_break_timer: boolean;
  desktop_notifications: boolean;
  long_break_duration: number;
  max_round_number: number;
  minimize_to_tray: boolean;
  minimize_to_tray_on_close: boolean;
  pomodoro_duration: number;
  short_break_duration: number;
  tick_sounds_during_work: boolean;
  tick_sounds_during_break: boolean;
};

const root = document.querySelector("#app div");

let rustConfig: RustConfig = {
  always_on_top: true,
  auto_start_work_timer: true,
  auto_start_break_timer: true,
  desktop_notifications: true,
  long_break_duration: 1200,
  max_round_number: 4,
  minimize_to_tray: true,
  minimize_to_tray_on_close: true,
  pomodoro_duration: 1500,
  short_break_duration: 300,
  tick_sounds_during_work: true,
  tick_sounds_during_break: true,
};

const app = Elm.Main.init({
  node: root,
  flags: {
    alwaysOnTop: rustConfig.always_on_top,
    autoStartWorkTimer: rustConfig.auto_start_work_timer,
    autoStartBreakTimer: rustConfig.auto_start_break_timer,
    desktopNotifications: rustConfig.desktop_notifications,
    longBreakDuration: rustConfig.long_break_duration,
    maxRoundNumber: rustConfig.max_round_number,
    minimizeToTray: rustConfig.minimize_to_tray,
    minimizeToTrayOnClose: rustConfig.minimize_to_tray_on_close,
    pomodoroDuration: rustConfig.pomodoro_duration,
    shortBreakDuration: rustConfig.short_break_duration,
    tickSoundsDuringWork: rustConfig.tick_sounds_during_work,
    tickSoundsDuringBreak: rustConfig.tick_sounds_during_break,
  },
});

app.ports.playSound.subscribe(function (soundElementId: string) {
  info("Playing sound");
  invoke("play_sound_command", { soundId: soundElementId });
});

app.ports.minimizeWindow.subscribe(function () {
  invoke("minimize_window");
});

app.ports.closeWindow.subscribe(function () {
  invoke("close_window");
});

app.ports.loadRustConfig.subscribe(function () {
  invoke("load_config").then((config) => {
    app.ports.loadConfig.send(config);
  });
});

app.ports.notify.subscribe(function (notification: Notification) {
  invoke("notify", { notification: notification });
});

app.ports.updateConfig.subscribe(function (config: ElmConfig) {
  invoke("update_config", {
    config: {
      always_on_top: config.alwaysOnTop,
      auto_start_work_timer: config.autoStartWorkTimer,
      auto_start_break_timer: config.autoStartBreakTimer,
      desktop_notifications: config.desktopNotifications,
      long_break_duration: config.longBreakDuration,
      max_round_number: config.maxRoundNumber,
      minimize_to_tray: config.minimizeToTray,
      minimize_to_tray_on_close: config.minimizeToTrayOnClose,
      pomodoro_duration: config.pomodoroDuration,
      short_break_duration: config.shortBreakDuration,
      tick_sounds_during_work: config.tickSoundsDuringWork,
      tick_sounds_during_break: config.tickSoundsDuringBreak,
    },
  });
});

app.ports.updateCurrentState.subscribe(function (state: ElmState) {
  invoke("update_play_tick", { playTick: state.playTick });
  invoke("change_icon", {
    red: state.color.r,
    green: state.color.g,
    blue: state.color.b,
    fillPercentage: state.percentage,
    paused: state.paused,
  });
});

await listen("tick-event", () => {
  app.ports.tick.send("");
});
