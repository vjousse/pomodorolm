import { Elm } from "../src/Main.elm";
var app = Elm.Main.init({ node: document.getElementById("elm-app") });

app.ports.playSound.subscribe(function (soundElementId) {
  document.getElementById(soundElementId).play();
});
