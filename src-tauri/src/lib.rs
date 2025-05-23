// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
pub mod cli;
pub mod gui;
mod icon;
pub mod pomodoro;
mod sound;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run_gui(config_dir_name: &str) {
    gui::run_app(config_dir_name, tauri::Builder::default())
}
