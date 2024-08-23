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
use hex_color::HexColor;
use std::path::PathBuf;
use tauri::Emitter;
use tauri_plugin_notification::{NotificationExt, PermissionState};
use tokio_stream::wrappers::IntervalStream;
mod icon;
mod sound;

const CONFIG_DIR_NAME: &str = "pomodorolm";

#[derive(Debug, Serialize, Deserialize, Clone)]
struct App {
    play_tick: bool,
    config: Config,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
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
    #[serde(default = "default_theme")]
    theme: String,
    tick_sounds_during_work: bool,
    tick_sounds_during_break: bool,
}

fn default_theme() -> String {
    "pomotroid".to_string()
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct Colors {
    accent: String,
    background: String,
    background_light: String,
    background_lightest: String,
    focus_round: String,
    focus_round_middle: String,
    focus_round_end: String,
    foreground: String,
    foreground_darker: String,
    foreground_darkest: String,
    long_round: String,
    short_round: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct Theme {
    colors: Colors,
    name: String,
}

impl From<JsonTheme> for Theme {
    fn from(json_theme: JsonTheme) -> Self {
        let (focus_round_middle, focus_round_end) = match (
            json_theme.colors.focus_round_middle,
            json_theme.colors.focus_round_end,
        ) {
            (Some(middle), Some(end)) => (middle, end),
            _ => match (
                HexColor::parse(json_theme.colors.short_round.as_str()),
                HexColor::parse(json_theme.colors.focus_round.as_str()),
            ) {
                // If middle or end are not provided, try to compute the middle color ourself
                // It will be the middle gradient between the focus round color and the short round
                // color
                (
                    Ok(HexColor {
                        r: r1,
                        g: g1,
                        b: b1,
                        a: _a1,
                    }),
                    Ok(HexColor {
                        r: r2,
                        g: g2,
                        b: b2,
                        a: _a2,
                    }),
                ) => {
                    // Middle of the 2 colors
                    let t = 0.5;
                    // Compute the middle gradient color
                    let r = ((1.0 - t) * r1 as f32 + t * r2 as f32).round() as u8;
                    let g = ((1.0 - t) * g1 as f32 + t * g2 as f32).round() as u8;
                    let b = ((1.0 - t) * b1 as f32 + t * b2 as f32).round() as u8;
                    // RGB to hex
                    (
                        format!("#{:02X}{:02X}{:02X}", r, g, b),
                        json_theme.colors.short_round.clone(),
                    )
                }
                _ => (
                    json_theme.colors.focus_round.clone(),
                    json_theme.colors.focus_round.clone(),
                ),
            },
        };

        Theme {
            colors: Colors {
                accent: json_theme.colors.accent,
                background: json_theme.colors.background,
                background_light: json_theme.colors.background_light,
                background_lightest: json_theme.colors.background_lightest,
                focus_round: json_theme.colors.focus_round,
                focus_round_middle,
                focus_round_end,
                foreground: json_theme.colors.foreground,
                foreground_darker: json_theme.colors.foreground_darker,
                foreground_darkest: json_theme.colors.foreground_darkest,
                long_round: json_theme.colors.long_round,
                short_round: json_theme.colors.short_round,
            },
            name: json_theme.name,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct JsonColors {
    #[serde(rename = "--color-accent")]
    accent: String,
    #[serde(rename = "--color-background")]
    background: String,
    #[serde(rename = "--color-background-light")]
    background_light: String,
    #[serde(rename = "--color-background-lightest")]
    background_lightest: String,
    #[serde(rename = "--color-focus-round")]
    focus_round: String,
    #[serde(rename = "--color-focus-round-middle")]
    focus_round_middle: Option<String>,
    #[serde(rename = "--color-focus-round-end")]
    focus_round_end: Option<String>,
    #[serde(rename = "--color-foreground")]
    foreground: String,
    #[serde(rename = "--color-foreground-darker")]
    foreground_darker: String,
    #[serde(rename = "--color-foreground-darkest")]
    foreground_darkest: String,
    #[serde(rename = "--color-long-round")]
    long_round: String,
    #[serde(rename = "--color-short-round")]
    short_round: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct JsonTheme {
    colors: JsonColors,
    name: String,
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
            theme: "pomotroid".to_string(),
            tick_sounds_during_work: true,
            tick_sounds_during_break: true,
        }
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    run_app(tauri::Builder::default())
}

fn get_config_file_path<R: Runtime>(
    path: &tauri::path::PathResolver<R>,
) -> Result<PathBuf, tauri::Error> {
    path.resolve(
        format!("{}/config.toml", CONFIG_DIR_NAME),
        BaseDirectory::Config,
    )
}

fn get_config_dir<R: Runtime>(
    path: &tauri::path::PathResolver<R>,
) -> Result<PathBuf, tauri::Error> {
    path.resolve(format!("{}/", CONFIG_DIR_NAME), BaseDirectory::Config)
}

fn get_config_theme_dir<R: Runtime>(
    path: &tauri::path::PathResolver<R>,
) -> Result<PathBuf, tauri::Error> {
    path.resolve(
        format!("{}/themes/", CONFIG_DIR_NAME),
        BaseDirectory::Config,
    )
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

                            let state_guard = state.0.lock();
                            match state_guard {
                                Ok(guard) => {
                                    let set_text_result = guard.set_text(new_title);
                                    if let Err(e) = set_text_result {
                                        eprintln!("Error setting MenuItem title: {:?}.", e);
                                    }
                                }
                                Err(e) => eprintln!("Error getting state lock: {:?}.", e),
                            };
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

            let config_file_path = get_config_file_path(app.path())?;

            let metadata = fs::metadata(&config_file_path);
            let _ = fs::create_dir_all(get_config_theme_dir(app.path())?);

            let config = if metadata.is_err() {
                // Be sure to create the directory if it doesn't exist. It seems that on Mac, the
                // Application Support/pomodorolm directory has to be created by hand
                let _ = fs::create_dir_all(get_config_dir(app.path())?);

                let mut file = OpenOptions::new()
                    .read(true)
                    .write(true)
                    .create(true)
                    .truncate(true)
                    .open(config_file_path)?;

                let default_config = Config {
                    ..Default::default()
                };

                file.write_all(toml::to_string(&default_config)?.as_bytes())?;
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

            let sound_file =
                sound::get_sound_file("audio-tick").expect("Tick sound file not found.");

            let path = &app.path();

            let resource_path =
                path.resolve(format!("audio/{}", sound_file), BaseDirectory::Resource);
            let audio_path = resource_path
                .expect(format!("Unable to resolve `audio/{}` resource.", sound_file).as_str());

            tauri::async_runtime::spawn(tick(
                app.handle().clone(),
                String::from(
                    audio_path
                        .to_str()
                        .expect("Unable to convert tick audio path to string."),
                ),
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

fn get_themes_for_directory(
    app_handle: &AppHandle,
    path_to_resolve: String,
    base_directory: BaseDirectory,
) -> Vec<PathBuf> {
    let mut themes_paths_bufs: Vec<PathBuf> = vec![];
    let themes_path = app_handle
        .path()
        .resolve(path_to_resolve, base_directory)
        .expect("Unable to resolve `themes/{}` resource.");
    let themes_path_dir = fs::read_dir(themes_path);

    match themes_path_dir {
        Ok(path_dir) => {
            for p in path_dir {
                match p {
                    Ok(p_ok) => themes_paths_bufs.push(p_ok.path()),
                    Err(e) => eprintln!("Error reading theme path dir: {:?}.", e),
                }
            }
        }
        Err(e) => {
            eprintln!("Unable to read builtin themes path: {:?}.", e);
        }
    }

    themes_paths_bufs
}

fn load_themes(app_handle: AppHandle) {
    let mut themes_paths: Vec<PathBuf> = get_themes_for_directory(
        &app_handle,
        String::from("themes/"),
        BaseDirectory::Resource,
    );

    themes_paths.extend_from_slice(&get_themes_for_directory(
        &app_handle,
        format!("{}/themes/", CONFIG_DIR_NAME),
        BaseDirectory::Config,
    ));

    let mut themes: Vec<Theme> = vec![];

    for path in themes_paths {
        let file = fs::File::open(path.clone()).expect("file should open read only");
        let loaded_theme: Result<JsonTheme, serde_json::Error> = serde_json::from_reader(file);

        match loaded_theme {
            Ok(theme) => themes.push(Theme::from(theme)),
            Err(err) => eprintln!("Impossible to read JSON {}: {:?}", path.display(), err),
        }
    }
    let _ = app_handle.emit("themes", &themes).unwrap();
}

async fn tick(app_handle: AppHandle, path: String) {
    let mut stream = IntervalStream::new(time::interval(Duration::from_secs(1)));

    match app_handle.get_webview_window("main") {
        Some(window) => {
            while let Some(_ts) = stream.next().await {
                let _ = window.emit("tick-event", "");

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
        None => eprintln!("Impossible to get main window for tick sound"),
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

    match app_handle.path().app_data_dir() {
        Ok(data_dir) => {
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
        Err(e) => eprintln!("Unable to get app_data_dir for icon: {:?}.", e),
    }
}

#[tauri::command]
async fn update_play_tick(state: tauri::State<'_, AppState>, play_tick: bool) -> Result<(), ()> {
    let mut state_guard = state.0.lock().await;

    *state_guard = App {
        play_tick,
        config: state_guard.config.clone(),
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
        config: config.clone(),
    };

    match get_config_file_path(app_handle.path()) {
        Ok(config_file_pathbuf) => {
            let config_file_path = config_file_pathbuf.to_string_lossy().to_string();

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
        }
        Err(e) => eprintln!("Unable to get config file path: {:?}.", e),
    }

    Ok(())
}

#[tauri::command]
async fn load_config(
    state: tauri::State<'_, AppState>,
    app_handle: tauri::AppHandle,
) -> Result<Config, ()> {
    let mut state_guard = state.0.lock().await;

    match get_config_file_path(app_handle.path()) {
        Ok(config_file_pathbuf) => {
            let config_file_path = config_file_pathbuf.to_string_lossy().to_string();

            let toml_str = fs::read_to_string(&config_file_path).map_err(|err| {
                eprintln!("Unable to open config file {}: {:?}", config_file_path, err)
            })?;

            let config: Config = toml::from_str(toml_str.as_str()).map_err(|err| {
                eprintln!(
                    "Unable to parse config file {}: {:?}",
                    config_file_path, err
                )
            })?;

            *state_guard = App {
                play_tick: state_guard.play_tick,
                config: config.clone(),
            };

            let _ = load_themes(app_handle.clone());

            Ok(config)
        }
        Err(e) => {
            eprintln!("Unable to get config file path: {:?}.", e);
            Err(())
        }
    }
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
