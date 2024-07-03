// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::sync::Arc;
use std::time::Duration;
use tauri::menu::{MenuBuilder, MenuItemBuilder};
use tauri::tray::TrayIconEvent;
use tauri::tray::{MouseButton, MouseButtonState, TrayIconBuilder};
use tauri::AppHandle;
use tauri::Runtime;
use tauri::{path::BaseDirectory, Manager};
use tokio::sync::Mutex;
use tokio::time; // 1.3.0 //
pub struct AppState(Arc<Mutex<App>>);
pub struct MenuState<R: Runtime>(std::sync::Mutex<tauri::menu::MenuItem<R>>);
use futures::StreamExt;
use tauri_plugin_notification::{NotificationExt, PermissionState};
use tokio_stream::wrappers::IntervalStream;

mod icon;
mod sound;

#[derive(Debug, Serialize, Deserialize, Clone)]
struct App {
    play_tick: bool,
    config: Config,
}

#[derive(Debug, Serialize, Deserialize, Copy, Clone)]
struct Config {
    always_on_top: bool,
    auto_start_work_timer: bool,
    auto_start_break_timer: bool,
    desktop_notifications: bool,
    long_break_duration: u16,
    max_round_number: u16,
    minimize_to_tray: bool,
    minimize_to_tray_on_close: bool,
    pomodoro_duration: u16,
    short_break_duration: u16,
    tick_sounds_during_work: bool,
    tick_sounds_during_break: bool,
}

#[derive(Debug, Deserialize)]
struct ElmNotification {
    body: String,
    title: String,
    red: u8,
    green: u8,
    blue: u8,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            always_on_top: true,
            auto_start_work_timer: true,
            auto_start_break_timer: true,
            desktop_notifications: true,
            long_break_duration: 20 * 60,
            max_round_number: 4u16,
            minimize_to_tray: true,
            minimize_to_tray_on_close: true,
            pomodoro_duration: 25 * 60,
            short_break_duration: 5 * 60,
            tick_sounds_during_work: true,
            tick_sounds_during_break: true,
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    run_app(tauri::Builder::default())
}

pub fn run_app<R: Runtime>(_builder: tauri::Builder<R>) {
    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            if app.notification().permission_state()? == PermissionState::Unknown {
                app.notification().request_permission()?;
            }
            let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)?;
            let toggle_visibility =
                MenuItemBuilder::with_id("toggle_visibility", "Hide").build(app)?;

            let tray_menu = MenuBuilder::new(app)
                .item(&toggle_visibility)
                .separator()
                .item(&quit)
                .build()?;

            let _ = TrayIconBuilder::with_id("app-tray")
                .menu(&tray_menu)
                .on_menu_event(move |app, event| match event.id().as_ref() {
                    "quit" => {
                        app.exit(0);
                    }
                    "toggle_visibility" => {
                        if let Some(window) = app.get_webview_window("main") {
                            let new_title = if window.is_visible().unwrap_or_default() {
                                let _ = window.hide();
                                "Show"
                            } else {
                                let _ = window.show();
                                let _ = window.set_focus();
                                "Hide"
                            };

                            let state: tauri::State<'_, MenuState<R>> = app.state();

                            let state_guard = state.0.lock().unwrap();

                            let _ = state_guard.set_text(new_title);
                        }
                    }
                    _ => (),
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        let app = tray.app_handle();
                        if let Some(webview_window) = app.get_webview_window("main") {
                            let _ = webview_window.show();
                            let _ = webview_window.set_focus();
                        }
                    }
                })
                .build(app);

            let config_file_path = &app
                .path()
                .resolve("config.toml", BaseDirectory::AppConfig)?;

            let metadata = fs::metadata(config_file_path);

            let config = if metadata.is_err() {
                // Be sure to create the directory if it doesn't exist. It seems that on Mac, the
                // Application Support/pomodorolm directory has to be created by hand
                fs::create_dir_all(app.path().app_config_dir()?)?;

                let mut file = OpenOptions::new()
                    .read(true)
                    .write(true)
                    .create(true)
                    .truncate(true)
                    .open(config_file_path)?;

                let default_config = Config {
                    ..Default::default()
                };

                file.write_all(toml::to_string(&default_config).unwrap().as_bytes())?;
                default_config
            } else {
                // Open the file
                let toml_str = fs::read_to_string(config_file_path)?;
                let config: Config = toml::from_str(toml_str.as_str())?;

                config
            };

            app.manage(AppState(Arc::new(Mutex::new(App {
                play_tick: false,
                config,
            }))));

            app.manage(MenuState(std::sync::Mutex::new(toggle_visibility)));

            let sound_file = sound::get_sound_file("audio-tick").unwrap();

            let path = &app.path();

            let resource_path =
                path.resolve(format!("audio/{}", sound_file), BaseDirectory::Resource);
            let audio_path = resource_path.unwrap();

            tauri::async_runtime::spawn(tick(
                app.handle().clone(),
                String::from(audio_path.to_str().unwrap()),
            ));

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            change_icon,
            close_window,
            hide_window,
            load_config,
            minimize_window,
            notify,
            play_sound_command,
            update_config,
            update_play_tick
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

async fn tick(app_handle: AppHandle, path: String) {
    let mut stream = IntervalStream::new(time::interval(Duration::from_secs(1)));

    let window = app_handle.get_webview_window("main").unwrap();
    while let Some(_ts) = stream.next().await {
        window.emit("tick-event", "").unwrap();

        let state: tauri::State<AppState> = app_handle.state();
        let new_state = state.clone();
        let state_guard = new_state.0.lock().await;
        let play_tick: bool = state_guard.play_tick;

        let new_path = path.clone();

        tauri::async_runtime::spawn_blocking(move || {
            if play_tick {
                // Fail silently if we can't play sound file
                let _ = sound::play_sound_file(&new_path);
            }
        });
    }
}

#[tauri::command]
async fn change_icon(
    app_handle: tauri::AppHandle,
    red: u8,
    green: u8,
    blue: u8,
    fill_percentage: f32,
    paused: bool,
) {
    // Image dimensions
    let width = 512;
    let height = 512;

    let data_dir = app_handle.path().app_data_dir().unwrap();

    let icon_path_buf = icon::create_icon(
        icon::PomodorolmIcon {
            width,
            height,
            red,
            green,
            blue,
            fill_percentage,
            paused,
        },
        format!("{}/temp_icon_tray.png", data_dir.to_string_lossy()).as_str(),
    );

    if let Some(tray) = app_handle.tray_by_id("app-tray") {
        let _ = tray.set_icon(tauri::image::Image::from_path(icon_path_buf).ok());
    }
}

#[tauri::command]
async fn update_play_tick(state: tauri::State<'_, AppState>, play_tick: bool) -> Result<(), ()> {
    let mut state_guard = state.0.lock().await;

    *state_guard = App {
        play_tick,
        config: state_guard.config,
    };

    Ok(())
}

#[tauri::command]
async fn update_config(
    state: tauri::State<'_, AppState>,
    app_handle: tauri::AppHandle,
    config: Config,
) -> Result<(), ()> {
    let mut state_guard = state.0.lock().await;

    *state_guard = App {
        play_tick: state_guard.play_tick,
        config,
    };

    let config_dir = app_handle.path().app_config_dir().unwrap();
    let config_file_path = &format!("{}/config.toml", config_dir.to_string_lossy());

    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(true)
        .open(config_file_path);

    let _ = match file {
        Ok(mut f) => f.write_all(toml::to_string(&config).unwrap().as_bytes()),
        Err(_) => {
            println!("Error opening config file on update");
            Ok(())
        }
    };

    Ok(())
}

#[tauri::command]
async fn load_config(
    state: tauri::State<'_, AppState>,
    app_handle: tauri::AppHandle,
) -> Result<Config, ()> {
    let mut state_guard = state.0.lock().await;

    let config_dir = app_handle.path().app_config_dir().unwrap();

    let config_file_path = &format!("{}/config.toml", config_dir.to_string_lossy());
    let toml_str = fs::read_to_string(config_file_path)
        .expect(&format!("Unable to open config file {}", config_file_path)[..]);
    let config: Config = toml::from_str(toml_str.as_str()).expect("Unable to parse config file");
    *state_guard = App {
        play_tick: state_guard.play_tick,
        config,
    };

    Ok(config)
}

#[tauri::command]
async fn play_sound_command(app_handle: tauri::AppHandle, sound_id: String) {
    let sound_file = sound::get_sound_file(sound_id.as_str()).unwrap();

    let resource_path = app_handle
        .path()
        .resolve(format!("audio/{}", sound_file), BaseDirectory::Resource)
        .unwrap();
    let path = resource_path.to_string_lossy();

    // Fail silently if we can't play sound file
    let _ = sound::play_sound_file(&path);
}

#[tauri::command]
fn minimize_window<R: tauri::Runtime>(
    app: tauri::AppHandle<R>,
    app_menu: tauri::State<'_, MenuState<R>>,
) -> Result<(), ()> {
    let state_guard = app_menu.0.lock().unwrap();

    if let Some(window) = app.get_webview_window("main") {
        let _ = window.minimize();
        let _ = state_guard.set_text("Show");
    }
    Ok(())
}

#[tauri::command]
fn hide_window<R: tauri::Runtime>(
    app: tauri::AppHandle<R>,
    app_menu: tauri::State<'_, MenuState<R>>,
) -> Result<(), ()> {
    let state_guard = app_menu.0.lock().unwrap();

    if let Some(window) = app.get_webview_window("main") {
        let _ = window.hide();
        let _ = state_guard.set_text("Show");
    }
    Ok(())
}

#[tauri::command]
async fn close_window(app_handle: tauri::AppHandle) {
    let window = app_handle
        .get_webview_window("main")
        .expect("window not found");

    window.close().expect("failed to close window");
}

#[tauri::command]
async fn notify(app_handle: tauri::AppHandle, notification: ElmNotification) {
    let data_dir = app_handle.path().app_data_dir().unwrap();
    let icon_path_buf = icon::create_icon(
        icon::PomodorolmIcon {
            width: 512,
            height: 512,
            red: notification.red,
            green: notification.green,
            blue: notification.blue,
            fill_percentage: 1_f32,
            paused: false,
        },
        format!("{}/temp_icon_notification.png", data_dir.to_string_lossy()).as_str(),
    );

    // shows a notification with the given title and body
    if app_handle.notification().permission_state().unwrap() == PermissionState::Granted {
        let _ = app_handle
            .notification()
            .builder()
            .title(notification.title)
            .body(notification.body)
            .icon(icon_path_buf.to_string_lossy())
            .show();
    }
}
