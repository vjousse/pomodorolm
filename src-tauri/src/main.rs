// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use image::{ImageBuffer, Rgba};
use std::path::Path;
use tauri::{CustomMenuItem, SystemTray, SystemTrayMenu, SystemTrayMenuItem};

fn main() {
    let quit = CustomMenuItem::new("quit".to_string(), "Quit");
    let hide = CustomMenuItem::new("hide".to_string(), "Hide");

    let tray_menu = SystemTrayMenu::new()
        .add_item(quit)
        .add_native_item(SystemTrayMenuItem::Separator)
        .add_item(hide);

    let system_tray = SystemTray::new().with_menu(tray_menu);

    tauri::Builder::default()
        .system_tray(system_tray)
        .invoke_handler(tauri::generate_handler![change_icon])
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
