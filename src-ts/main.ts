import "../main.css";

import { Elm } from "../src-elm/Main.elm";

import { invoke } from "@tauri-apps/api";

const root = document.querySelector("#app div");
const app = Elm.Main.init({ node: root });

app.ports.playSound.subscribe(function (soundElementId: string) {
  invoke("play_sound", { soundId: soundElementId });
});

app.ports.minimizeWindow.subscribe(function () {
  invoke("minimize_window");
});

app.ports.closeWindow.subscribe(function () {
  invoke("close_window");
});

type Color = {
  r: number;
  g: number;
  b: number;
};
type ElmState = {
  color: Color;
  percentage: number;
  paused: boolean;
};

app.ports.updateCurrentState.subscribe(function (state: ElmState) {
  invoke("change_icon", {
    red: state.color.r,
    green: state.color.g,
    blue: state.color.b,
    fillPercentage: state.percentage,
    paused: state.paused,
  });
});
