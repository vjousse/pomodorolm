// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
pub mod cli;
pub mod gui;
mod icon;
pub mod pomodoro;
mod sound;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run_gui() {
    gui::run_app(tauri::Builder::default().plugin(tauri_plugin_dialog::init()))
}
