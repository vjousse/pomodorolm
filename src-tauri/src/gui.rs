// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
// Fix for https://github.com/tauri-apps/tauri/issues/12382
#![allow(deprecated)]

use crate::config::Config;
use crate::icon;
use crate::pomodoro;
use crate::sound;
use pomodoro::{Pomodoro, SessionStatus, SessionType};
use serde::{Deserialize, Serialize};
use std::fs;
use std::fs::OpenOptions;
use std::io::Write;
use std::sync::Arc;
use std::time::Duration;
use tauri::menu::{MenuBuilder, MenuItemBuilder};
use tauri::tray::TrayIconBuilder;
use tauri::AppHandle;
use tauri::Runtime;
use tauri::{path::BaseDirectory, Manager};
use tokio::sync::Mutex;
use tokio::time; // 1.3.0 //
pub struct AppState(Arc<Mutex<App>>);
pub struct AppMenuStates<R: Runtime>(std::sync::Mutex<MenuStates<R>>);
use futures::StreamExt;
use hex_color::HexColor;
use std::path::PathBuf;
use tauri::Emitter;
use tauri_plugin_notification::{NotificationExt, PermissionState};
use tokio_stream::wrappers::IntervalStream;

#[derive(Debug, Serialize, Deserialize, Clone)]
struct App {
    config: Config,
    config_dir_name: String,
    pomodoro: pomodoro::Pomodoro,
}

struct MenuStates<R: Runtime> {
    toggle_visibility_menu: tauri::menu::MenuItem<R>,
    toggle_play_menu: tauri::menu::MenuItem<R>,
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
                        format!("#{r:02X}{g:02X}{b:02X}"),
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

fn get_config_file_path<R: Runtime>(
    config_dir_name: &str,
    path: &tauri::path::PathResolver<R>,
) -> Result<PathBuf, tauri::Error> {
    let config_dir = get_config_dir(config_dir_name, path)?;
    Ok(Config::get_config_file_path(&config_dir, None))
}

fn get_config_dir<R: Runtime>(
    config_dir_name: &str,
    path: &tauri::path::PathResolver<R>,
) -> Result<PathBuf, tauri::Error> {
    path.resolve(format!("{config_dir_name}/"), BaseDirectory::Config)
}

pub fn run_app<R: Runtime>(config_dir_name: &str, _builder: tauri::Builder<R>) {
    let config_dir_name_owned = config_dir_name.to_string();

    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            let window = app.get_webview_window("main").expect("no main window");

            let _ = window.show();
            let _ = window.set_focus();
        }))
        .setup(|app| {
            if app.notification().permission_state()? == PermissionState::Prompt {
                app.notification().request_permission()?;
            }
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);
            let quit = MenuItemBuilder::with_id("quit", "Quit").build(app)?;
            let toggle_visibility =
                MenuItemBuilder::with_id("toggle_visibility", "Hide").build(app)?;
            let skip = MenuItemBuilder::with_id("skip", "Skip").build(app)?;
            let toggle_play = MenuItemBuilder::with_id("toggle_play", "Play").build(app)?;

            let tray_menu = MenuBuilder::new(app)
                .item(&skip)
                .item(&toggle_play)
                .separator()
                .item(&toggle_visibility)
                .separator()
                .item(&quit)
                .build()?;

            let _ = TrayIconBuilder::with_id("app-tray")
                .menu(&tray_menu)
                .on_menu_event(move |app, event| {
                    println!("On menu event {event:?}");
                    match event.id().as_ref() {
                        "quit" => {
                            app.exit(0);
                        }
                        "toggle_play" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.emit("toggle-play", "");
                            }
                        }
                        "skip" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.emit("skip", "");
                            }
                        }
                        "toggle_visibility" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let new_title = if window.is_visible().unwrap_or_default() {
                                    #[cfg(target_os = "macos")]
                                    let _ = app.hide();
                                    #[cfg(not(target_os = "macos"))]
                                    let _ = window.hide();
                                    "Show"
                                } else {
                                    #[cfg(target_os = "macos")]
                                    let _ = app.show();
                                    let _ = window.show();
                                    let _ = window.set_focus();
                                    "Hide"
                                };

                                let state: tauri::State<'_, AppMenuStates<R>> = app.state();

                                let state_guard = state.0.lock();
                                match state_guard {
                                    Ok(guard) => {
                                        let set_text_result =
                                            guard.toggle_visibility_menu.set_text(new_title);
                                        if let Err(e) = set_text_result {
                                            eprintln!("Error setting MenuItem title: {e:?}.");
                                        }
                                    }
                                    Err(e) => eprintln!("Error getting state lock: {e:?}."),
                                };
                            }
                        }
                        _ => (),
                    }
                })
                .build(app);

            let config = read_config_from_disk(&config_dir_name_owned, app.path())?;

            if let Some(window) = app.get_webview_window("main") {
                if config.start_minimized {
                    #[cfg(target_os = "macos")]
                    let _ = app.hide();
                    #[cfg(not(target_os = "macos"))]
                    let _ = window.hide();
                    let _ = toggle_visibility.set_text("Show");
                }
            }

            let pomodoro = pomodoro_state_from_config(&config);

            app.manage(AppState(Arc::new(Mutex::new(App {
                config: config.clone(),
                config_dir_name: config_dir_name_owned,
                pomodoro,
            }))));

            app.manage(AppMenuStates(std::sync::Mutex::new(MenuStates {
                toggle_visibility_menu: toggle_visibility,
                toggle_play_menu: toggle_play,
            })));

            let sound_file_path = get_sound_file("audio-tick", app.handle(), &config)
                .expect("Tick sound file not found.");
            let audio_path = sound_file_path.to_string_lossy();

            tauri::async_runtime::spawn(tick(app.handle().clone(), audio_path.to_string()));

            #[cfg(desktop)]
            {
                use tauri_plugin_autostart::MacosLauncher;

                app.handle().plugin(tauri_plugin_autostart::init(
                    MacosLauncher::LaunchAgent,
                    Some(vec![]),
                ))?;
                manage_autostart(app.handle(), config.system_startup_auto_start)?;
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            change_icon,
            close_window,
            handle_external_message,
            hide_window,
            load_init_data,
            minimize_window,
            notify,
            play_sound_command,
            update_config,
            update_session_status
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn manage_autostart(
    app_handle: &AppHandle,
    system_startup_auto_start: bool,
) -> Result<(), Box<dyn std::error::Error>> {
    #[cfg(desktop)]
    {
        use tauri_plugin_autostart::ManagerExt;

        // Get the autostart manager
        let autostart_manager = app_handle.autolaunch();

        if system_startup_auto_start != autostart_manager.is_enabled()? {
            if system_startup_auto_start {
                let _ = autostart_manager.enable();
            } else {
                let _ = autostart_manager.disable();
            }
        }
    }
    Ok(())
}

fn read_config_from_disk<R: Runtime>(
    config_dir_name: &str,
    app_path: &tauri::path::PathResolver<R>,
) -> Result<Config, Box<dyn std::error::Error>> {
    let config_dir = get_config_dir(config_dir_name, app_path)?;

    Config::get_or_create_from_disk(&config_dir, None)
}

fn pomodoro_config(config: &Config) -> pomodoro::Config {
    pomodoro::Config {
        auto_start_long_break_timer: config.auto_start_break_timer,
        auto_start_short_break_timer: config.auto_start_break_timer,
        auto_start_focus_timer: config.auto_start_work_timer,
        focus_duration: config.focus_duration,
        long_break_duration: config.long_break_duration,
        max_focus_rounds: config.max_round_number,
        short_break_duration: config.short_break_duration,
    }
}

fn pomodoro_state_from_config(config: &Config) -> Pomodoro {
    pomodoro::Pomodoro {
        config: pomodoro_config(config),
        ..pomodoro::Pomodoro::default()
    }
}

fn get_themes_for_directory(themes_path: PathBuf) -> Vec<PathBuf> {
    let mut themes_paths_bufs: Vec<PathBuf> = vec![];
    let themes_path_dir = fs::read_dir(themes_path.clone());

    match themes_path_dir {
        Ok(path_dir) => {
            for p in path_dir {
                match p {
                    Ok(p_ok) => themes_paths_bufs.push(p_ok.path()),
                    Err(e) => eprintln!("Error reading theme path dir: {e:?}."),
                }
            }
        }
        Err(e) => {
            eprintln!("Unable to read builtin themes path {themes_path:?}: {e:?}.");
        }
    }

    themes_paths_bufs
}

fn should_play_tick_sound(config: &Config, pomodoro: &Pomodoro) -> bool {
    match (
        pomodoro.current_session.status,
        pomodoro.current_session.session_type,
        config.tick_sounds_during_work,
        config.tick_sounds_during_break,
        config.muted,
    ) {
        // No tick sound configured
        (_, _, _, _, true) => false,
        (_, _, false, false, _) => false,
        (SessionStatus::Running, SessionType::Focus, true, _, _) => true,
        (SessionStatus::Running, SessionType::LongBreak, _, true, _) => true,
        (SessionStatus::Running, SessionType::ShortBreak, _, true, _) => true,
        _ => false,
    }
}

async fn tick(app_handle: AppHandle, path: String) {
    let mut stream = IntervalStream::new(time::interval(Duration::from_secs(1)));

    match app_handle.get_webview_window("main") {
        Some(window) => {
            while let Some(_ts) = stream.next().await {
                let new_path = path.clone();

                let state: tauri::State<AppState> = app_handle.state();
                let new_state = state.clone();
                let mut state_guard = new_state.0.lock().await;
                //let play_tick: bool = state_guard.play_tick;
                let play_tick: bool =
                    should_play_tick_sound(&state_guard.config, &state_guard.pomodoro);

                state_guard.pomodoro = pomodoro::tick(&state_guard.pomodoro);

                let _ = window.emit("external-message", state_guard.pomodoro.to_unborrowed());

                tauri::async_runtime::spawn_blocking(move || {
                    if play_tick {
                        // Fail silently if we can't play sound file
                        let play_sound_file_result = sound::play_sound_file(&new_path);
                        if play_sound_file_result.is_err() {
                            eprintln!(
                                "Unable to play sound file {new_path:?}: {play_sound_file_result:?}"
                            );
                        }
                    }
                });
            }
        }
        None => eprintln!("Impossible to get main window for tick sound"),
    }
}

#[tauri::command]
async fn change_icon<R: tauri::Runtime>(
    app_handle: tauri::AppHandle<R>,
    red: u8,
    green: u8,
    blue: u8,
    fill_percentage: f32,
    paused: bool,
) -> Result<(), ()> {
    // Image dimensions
    let width = 512;
    let height = 512;

    match app_handle.path().app_data_dir() {
        Ok(data_dir) => {
            match icon::create_icon(
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
            ) {
                Ok(icon_path_buf) => {
                    if let Some(tray) = app_handle.tray_by_id("app-tray") {
                        let icon_path = tauri::image::Image::from_path(icon_path_buf.clone()).ok();

                        // Don't let tauri choose where to store the temp icon path as it will by default store it to `/tmp`.
                        // Setting it manually allows the tray icon to work properly in sandboxes env like Flatpak
                        // where we can share XDG_DATA_HOME between the host and the sandboxed env
                        // libappindicator will add the full path of the icon to the dbus message when changing it,
                        // so the path needs to be the same between the host and the sandboxed env
                        let local_data_path = app_handle
                            .path()
                            .resolve("tray-icon", BaseDirectory::AppLocalData)
                            .unwrap();

                        let _ = tray.set_temp_dir_path(Some(local_data_path));
                        let _ = tray.set_icon(icon_path);
                    }
                }
                Err(e) => eprintln!("{e:?}"),
            }
        }
        Err(e) => eprintln!("Unable to get app_data_dir for icon: {e:?}."),
    }

    Ok(())
}

#[tauri::command]
async fn update_session_status<R: tauri::Runtime>(
    _app: tauri::AppHandle<R>,
    state: tauri::State<'_, AppMenuStates<R>>,
    status: String,
) -> Result<(), ()> {
    let state_guard = state.0.lock();

    match state_guard {
        Ok(guard) => {
            if status == "running" {
                let set_text_result = guard.toggle_play_menu.set_text("Pause");
                if let Err(e) = set_text_result {
                    eprintln!("Error setting MenuItem title: {e:?}.");
                }
            } else {
                let set_text_result = guard.toggle_play_menu.set_text("Play");
                if let Err(e) = set_text_result {
                    eprintln!("Error setting MenuItem title: {e:?}.");
                }
            }
        }
        Err(e) => eprintln!("Error getting state lock: {e:?}."),
    };

    Ok(())
}

#[tauri::command]
async fn update_config(
    state: tauri::State<'_, AppState>,
    app_handle: tauri::AppHandle,
    config: Config,
) -> Result<pomodoro::PomodoroUnborrowed, ()> {
    let mut state_guard = state.0.lock().await;

    // config: pomodoro_config(config),
    match get_config_file_path(&state_guard.config_dir_name, app_handle.path()) {
        Ok(config_file_pathbuf) => {
            let config_file_path = config_file_pathbuf.to_string_lossy().to_string();

            let file = OpenOptions::new()
                .read(true)
                .write(true)
                .create(true)
                .truncate(true)
                .open(config_file_path);

            // FIX: We should not fail silently and we should hanlde the errors properly
            let _: Result<(), _> = match file {
                Ok(mut f) => {
                    let _ = f.write_all(toml::to_string(&config).unwrap().as_bytes());

                    *state_guard = App {
                        config: config.clone(),
                        config_dir_name: state_guard.config_dir_name.clone(),
                        pomodoro: pomodoro::Pomodoro {
                            config: pomodoro_config(&config),
                            ..state_guard.pomodoro.clone()
                        },
                    };

                    // Manage autostart status
                    let _ = manage_autostart(&app_handle, config.system_startup_auto_start);

                    Ok::<(), ()>(())
                }
                Err(_) => {
                    println!("Error opening config file on update");
                    Ok(())
                }
            };
        }
        Err(e) => eprintln!("Unable to get config file path: {e:?}."),
    }

    Ok(state_guard.pomodoro.to_unborrowed())
}

#[tauri::command]
async fn load_init_data(
    state: tauri::State<'_, AppState>,
    app_handle: tauri::AppHandle,
) -> Result<(Config, Vec<Theme>, pomodoro::PomodoroUnborrowed), ()> {
    let mut state_guard = state.0.lock().await;

    let config = match get_config_file_path(&state_guard.config_dir_name, app_handle.path()) {
        Ok(config_file_pathbuf) => {
            let config_file_path = config_file_pathbuf.to_string_lossy().to_string();

            let toml_str = fs::read_to_string(&config_file_path).map_err(|err| {
                eprintln!("Unable to open config file {config_file_path}: {err:?}")
            })?;

            let config: Config = toml::from_str(toml_str.as_str()).map_err(|err| {
                eprintln!("Unable to parse config file {config_file_path}: {err:?}")
            })?;

            *state_guard = App {
                config: config.clone(),
                config_dir_name: state_guard.config_dir_name.clone(),
                pomodoro: state_guard.pomodoro.clone(),
            };

            Ok(config)
        }
        Err(e) => {
            eprintln!("Unable to get config file path: {e:?}.");
            Err(())
        }
    };

    let theme_resource_path = resolve_resource_path(&app_handle, String::from("themes/"))
        .expect("Unable to resolve `themes/{}` resource.");

    let mut themes_paths: Vec<PathBuf> = get_themes_for_directory(theme_resource_path);

    let custom_themes_path = app_handle.path().resolve(
        format!("{}/themes/", state_guard.config_dir_name),
        BaseDirectory::Config,
    );

    if let Ok(path) = custom_themes_path {
        themes_paths.extend_from_slice(&get_themes_for_directory(path));
    }

    let mut themes: Vec<Theme> = vec![];

    for path in themes_paths {
        let file = fs::File::open(path.clone()).expect("file should open read only");
        let loaded_theme: Result<JsonTheme, serde_json::Error> = serde_json::from_reader(file);

        match loaded_theme {
            Ok(theme) => themes.push(Theme::from(theme)),
            Err(err) => eprintln!("Impossible to read JSON {}: {:?}", path.display(), err),
        }
    }

    config.map(|c| (c, themes, state_guard.pomodoro.to_unborrowed()))
}

#[tauri::command]
async fn play_sound_command(app_handle: tauri::AppHandle, sound_id: String) {
    let state: tauri::State<AppState> = app_handle.state();
    let state_guard = state.0.lock().await;

    match get_sound_file(sound_id.as_str(), &app_handle, &state_guard.config) {
        Some(sound_file) => {
            // Fail silently if we can't play sound file

            tauri::async_runtime::spawn_blocking(move || {
                let play_sound_file_result = sound::play_sound_file(&sound_file.to_string_lossy());
                if play_sound_file_result.is_err() {
                    eprintln!(
                        "Unable to play sound file {sound_file:?}: {play_sound_file_result:?}"
                    );
                }
            });
        }
        None => eprintln!("Impossible to get sound file with id {sound_id}"),
    }
}

#[tauri::command]
fn minimize_window<R: tauri::Runtime>(
    app: tauri::AppHandle<R>,
    app_menu: tauri::State<'_, AppMenuStates<R>>,
) -> Result<(), ()> {
    let state_guard = app_menu.0.lock();
    match state_guard {
        Ok(guard) => {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.minimize();
                let _ = guard.toggle_visibility_menu.set_text("Show");
            }
            Ok(())
        }
        Err(e) => {
            eprintln!("Error getting state lock: {e:?}.");
            Err(())
        }
    }
}

#[tauri::command]
fn hide_window<R: tauri::Runtime>(
    app: tauri::AppHandle<R>,
    app_menu: tauri::State<'_, AppMenuStates<R>>,
) -> Result<(), ()> {
    let state_guard = app_menu.0.lock();
    match state_guard {
        Ok(guard) => {
            if let Some(window) = app.get_webview_window("main") {
                #[cfg(target_os = "macos")]
                let _ = app.hide();
                #[cfg(not(target_os = "macos"))]
                let _ = window.hide();
                let _ = guard.toggle_visibility_menu.set_text("Show");
            }
            Ok(())
        }
        Err(e) => {
            eprintln!("Error getting state lock: {e:?}.");
            Err(())
        }
    }
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
    match icon::create_icon(
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
    ) {
        Ok(icon_path_buf) => {
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
        Err(e) => eprintln!("Unable to get app_data_dir for icon: {e:?}."),
    }
}

#[tauri::command]
async fn handle_external_message(
    state: tauri::State<'_, AppState>,
    name: String,
) -> Result<pomodoro::PomodoroUnborrowed, ()> {
    let mut app_state_guard = state.0.lock().await;

    match name.as_str() {
        "pause" => {
            app_state_guard.pomodoro = pomodoro::pause(&app_state_guard.pomodoro);
        }
        "play" => {
            app_state_guard.pomodoro = pomodoro::play(&app_state_guard.pomodoro);
        }
        "reset" => {
            app_state_guard.pomodoro = pomodoro::reset(&app_state_guard.pomodoro);
        }
        "skip" => {
            app_state_guard.pomodoro = pomodoro::next(&app_state_guard.pomodoro);
        }
        message => eprintln!("[rust] Got unknown message `{message}`, ignoring."),
    }

    // Needed because Tauri doesn't play well with returning references
    // with async commands
    // https://v2.tauri.app/develop/calling-rust/#async-commands
    Ok(app_state_guard.pomodoro.to_unborrowed())
}

fn resolve_resource_path(
    app_handle: &AppHandle,
    path_to_resolve: String,
) -> Result<PathBuf, tauri::Error> {
    let mut resolved_path = app_handle
        .path()
        .resolve(path_to_resolve.clone(), BaseDirectory::Resource);

    #[cfg(target_os = "linux")]
    {
        let flatpak = std::env::var_os("FLATPAK");

        if flatpak.is_some() {
            let package_info = app_handle.package_info();

            resolved_path = Ok(PathBuf::from(format!(
                "/app/lib/{}/{}",
                package_info.crate_name, path_to_resolve
            )));
        }
    }

    if resolved_path.is_err() {
        eprintln!("Unable to resolve `{path_to_resolve}` resource.");
    }

    resolved_path
}

fn get_sound_file<'a>(
    sound_id: &'a str,
    app_handle: &AppHandle,
    config: &'a Config,
) -> Option<PathBuf> {
    match sound_id {
        "audio-long-break" => match &config.long_break_audio {
            Some(path) => Some(PathBuf::from(path)),
            None => {
                resolve_resource_path(app_handle, format!("audio/{}", "alert-long-break.mp3")).ok()
            }
        },
        "audio-short-break" => match &config.short_break_audio {
            Some(path) => Some(PathBuf::from(path)),
            None => {
                resolve_resource_path(app_handle, format!("audio/{}", "alert-short-break.mp3")).ok()
            }
        },
        "audio-work" => match &config.focus_audio {
            Some(path) => Some(PathBuf::from(path)),
            None => resolve_resource_path(app_handle, format!("audio/{}", "alert-work.mp3")).ok(),
        },
        "audio-tick" => resolve_resource_path(app_handle, format!("audio/{}", "tick.mp3")).ok(),
        _ => None,
    }
}
