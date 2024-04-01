import "../main.css";

import { Elm } from "../src-elm/Main.elm";

import { invoke } from "@tauri-apps/api";

if (process.env.NODE_ENV === "development") {
  const ElmDebugTransform = await import("elm-debug-transformer");

  ElmDebugTransform.register({
    simple_mode: true,
  });
}

const root = document.querySelector("#app div");
const app = Elm.Main.init({ node: root });

app.ports.playSound.subscribe(function (soundElementId: string) {
  let audioPlayer: HTMLVideoElement = document.getElementById(
    soundElementId
  ) as HTMLVideoElement;

  console.log("Playing sound");

  audioPlayer.play();
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
