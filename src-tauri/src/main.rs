// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use image::{ImageBuffer, Rgba};
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use std::{io::Write, path::Path};
use tauri::Manager;
use tauri::{CustomMenuItem, SystemTray, SystemTrayMenu, SystemTrayMenuItem};
use tauri_plugin_log::LogTarget;

use rodio::{source::Source, Decoder, OutputStream};
use std::fs;
use std::fs::File;
use std::fs::OpenOptions;
use std::io::BufReader;

pub struct ConfigState(Mutex<Config>);

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

fn main() {
    let quit = CustomMenuItem::new("quit".to_string(), "Quit");
    let hide = CustomMenuItem::new("hide".to_string(), "Hide");

    let tray_menu = SystemTrayMenu::new()
        .add_item(quit)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(hide);

    let system_tray = SystemTray::new().with_menu(tray_menu);

    tauri::Builder::default()
        .plugin(
            tauri_plugin_log::Builder::default()
                .targets([LogTarget::LogDir, LogTarget::Stdout, LogTarget::Webview])
                .build(),
        )
        .system_tray(system_tray)
        .setup(|app| {
            if let Some(config_dir) = app.path_resolver().app_config_dir() {
                let config_file_path = &format!("{}/config.toml", config_dir.to_string_lossy());

                let config = if !fs::metadata(config_file_path).is_ok() {
                    let mut file = OpenOptions::new()
                        .read(true)
                        .write(true)
                        .create(true)
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

                app.manage(ConfigState(Mutex::new(config)));
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            change_icon,
            close_window,
            load_config,
            minimize_window,
            play_sound,
            update_config
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
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

    // Create a new ImageBuffer with RGBA colors
    //let mut imgbuf = ImageBuffer::from_pixel(width, height, Rgba([0, 0, 0, 0])); // Transparent background
    let mut imgbuf = ImageBuffer::<Rgba<u8>, _>::new(width, height); // Transparent background
                                                                     //
                                                                     // Define circle parameters
    let center_x = width as f32 / 2.0;
    let center_y = height as f32 / 2.0;
    let outer_radius = width as f32 / 2.0;
    let inner_radius = outer_radius * 0.40; // 40% of the outer radius

    let start_angle = 0.0; // Start from the top center
    let end_angle = 360.0 * fill_percentage; // End at the specified percentage of the circle

    if paused {
        // Define parameters for the pause icon
        let icon_width = (width as f32 * 0.3) as i32; // Width of the pause bars
        let icon_height = (height as f32 * 0.6) as i32; // Height of the pause bars
        let bar_thickness = (width as f32 * 0.15) as i32; // Thickness of the pause bars
        let bar_spacing = (width as f32 * 0.01) as i32; // Spacing between the pause bars
                                                        //
                                                        // Calculate positions for the pause bars
        let first_bar_x = (width as i32 - bar_spacing - icon_width) / 2;
        let second_bar_x = first_bar_x + bar_spacing + icon_width;

        let bar_y = (height as i32 - icon_height) / 2;

        // Draw the first pause bar
        for y in bar_y..bar_y + icon_height {
            for x in first_bar_x..first_bar_x + bar_thickness {
                imgbuf.put_pixel(x as u32, y as u32, Rgba([red, green, blue, 255]));
                // Fill with white
            }
        }

        // Draw the second pause bar
        for y in bar_y..bar_y + icon_height {
            for x in second_bar_x..second_bar_x + bar_thickness {
                imgbuf.put_pixel(x as u32, y as u32, Rgba([red, green, blue, 255]));
                // Fill with white
            }
        }
    } else {
        // Draw the circle
        for y in 0..height {
            for x in 0..width {
                // Calculate the distance of the current pixel from the center of the outer circle
                let dx = x as f32 - center_x;
                let dy = center_y - y as f32; // Reverse y-axis to make it go upwards
                let distance_squared = dx * dx + dy * dy;

                // Check if the pixel is within the outer circle
                if distance_squared <= outer_radius * outer_radius {
                    // Calculate the angle of the current pixel relative to the center of the circle
                    let pixel_angle = (dx.atan2(dy).to_degrees() + 360.0) % 360.0;

                    // Check if the pixel angle is within the specified range and outside the inner circle
                    if pixel_angle >= start_angle
                        && pixel_angle <= end_angle
                        && distance_squared >= inner_radius * inner_radius
                    {
                        imgbuf.put_pixel(x, y, Rgba([red, green, blue, 255])); // Fill with red
                    }
                }
            }
        }
    }

    // Create a temporary file path
    let temp_path = Path::new("temp_icon.png");

    // Save the DynamicImage to the temporary file
    imgbuf.save(temp_path).expect("Failed to save image");

    // Set the icon using the temporary file
    app_handle
        .tray_handle()
        .set_icon(tauri::Icon::File(temp_path.to_path_buf()))
        .expect("Failed to set icon");
}

#[tauri::command]
fn update_config(state: tauri::State<ConfigState>, app_handle: tauri::AppHandle, config: Config) {
    let mut state_guard = state.0.lock().unwrap();

    *state_guard = config;

    if let Some(config_dir) = app_handle.path_resolver().app_config_dir() {
        let config_file_path = &format!("{}/config.toml", config_dir.to_string_lossy());

        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .open(config_file_path);

        let _ = match file {
            Ok(mut f) => f.write_all(toml::to_string(&config).unwrap().as_bytes()),
            Err(_) => {
                println!("Error opening config file on update");
                Ok(())
            }
        };
    };
}

#[tauri::command]
fn load_config(state: tauri::State<ConfigState>, app_handle: tauri::AppHandle) -> Config {
    let mut state_guard = state.0.lock().unwrap();

    let config: Config;

    let config_dir = app_handle
        .path_resolver()
        .app_config_dir()
        .expect("Impossible to get config dir");

    let config_file_path = &format!("{}/config.toml", config_dir.to_string_lossy());
    let toml_str = fs::read_to_string(config_file_path).expect("Unable to open config file");
    config = toml::from_str(toml_str.as_str()).expect("Unable to parse config file");
    *state_guard = config;

    return config;
}

#[tauri::command]
async fn play_sound(app_handle: tauri::AppHandle, sound_id: String) {
    let sound_file: Option<&str> = match sound_id.as_str() {
        "audio-long-break" => Some("alert-long-break.mp3"),
        "audio-short-break" => Some("alert-short-break.mp3"),
        "audio-work" => Some("alert-work.mp3"),
        "audio-tick" => Some("tick.mp3"),
        _ => None,
    };

    if let Some(file) = sound_file {
        let resource_path = app_handle
            .path_resolver()
            .resolve_resource(format!("audio/{}", file))
            .expect("failed to resolve resource");

        // Get a output stream handle to the default physical sound device
        let (_stream, stream_handle) = OutputStream::try_default().unwrap();
        // Load a sound from a file, using a path relative to Cargo.toml
        let file = BufReader::new(File::open(resource_path).unwrap());
        // Decode that sound file into a source
        let source = Decoder::new(file).unwrap();
        // Play the sound directly on the device
        let _ = stream_handle.play_raw(source.convert_samples());

        // The sound plays in a separate audio thread,
        // so we need to keep this thread alive while it's playing.
        std::thread::sleep(std::time::Duration::from_secs(5));
    }
}

#[tauri::command]
async fn minimize_window(app_handle: tauri::AppHandle) {
    let window = app_handle.get_window("main").expect("window not found");
    window.minimize().expect("failed to minimize window");
}

#[tauri::command]
async fn close_window(app_handle: tauri::AppHandle) {
    let window = app_handle.get_window("main").expect("window not found");
    window.close().expect("failed to close window");
}
