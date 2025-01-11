use image::{ImageBuffer, Rgba};
use std::{path::Path, path::PathBuf};

pub struct PomodorolmIcon {
    pub width: u32,
    pub height: u32,
    pub red: u8,
    pub green: u8,
    pub blue: u8,
    pub fill_percentage: f32,
    pub paused: bool,
}

pub fn create_icon(icon: PomodorolmIcon, path_name: &str) -> Result<PathBuf, String> {
    // Create a new ImageBuffer with RGBA colors
    let mut imgbuf = ImageBuffer::<Rgba<u8>, _>::new(icon.width, icon.height);

    let center_x = icon.width as f32 / 2.0;
    let center_y = icon.height as f32 / 2.0;
    let outer_radius = icon.width as f32 / 2.0;
    let inner_radius = outer_radius * 0.40; // 40% of the outer radius

    let start_angle = 0.0; // Start from the top center
    let end_angle = 360.0 * icon.fill_percentage; // End at the specified percentage of the circle

    // Define the width of the border circle
    let border_thickness = outer_radius * 0.05; // Adjust as needed

    let adjusted_outer_radius = outer_radius - outer_radius * 0.20;
    let adjusted_outer_radius_squared = adjusted_outer_radius * adjusted_outer_radius;
    let inner_border_radius_squared =
        (adjusted_outer_radius - border_thickness) * (adjusted_outer_radius - border_thickness);

    // Draw the thin border circle
    for y in 0..icon.height {
        for x in 0..icon.width {
            let dx = x as f32 - center_x;
            let dy = center_y - y as f32; // Reverse y-axis to make it go upwards
            let distance_squared = dx * dx + dy * dy;

            // Check if the pixel is within the border ring
            if distance_squared <= adjusted_outer_radius_squared
                && distance_squared >= inner_border_radius_squared
            {
                imgbuf.put_pixel(x, y, Rgba([192, 201, 218, 255])); // Gray color
            }
        }
    }

    if icon.paused {
        let bar_height = (icon.height as f32 * 0.6) as i32; // Height of the pause bars
        let bar_thickness = (icon.width as f32 * 0.175) as i32; // Thickness of the pause bars
        let bar_spacing = (icon.width as f32 * 0.15) as i32; // Spacing between the pause bars

        let first_bar_x = (icon.width / 2) as i32 - bar_spacing / 2 - bar_thickness;
        let second_bar_x = first_bar_x + bar_thickness + bar_spacing;

        let bar_y = (icon.height as i32 - bar_height) / 2;

        // Draw the first pause bar
        for y in bar_y..bar_y + bar_height {
            for x in first_bar_x..first_bar_x + bar_thickness {
                imgbuf.put_pixel(
                    x as u32,
                    y as u32,
                    Rgba([icon.red, icon.green, icon.blue, 255]),
                );
            }
        }

        // Draw the second pause bar
        for y in bar_y..bar_y + bar_height {
            for x in second_bar_x..second_bar_x + bar_thickness {
                imgbuf.put_pixel(
                    x as u32,
                    y as u32,
                    Rgba([icon.red, icon.green, icon.blue, 255]),
                );
            }
        }
    } else {
        // Draw the circle
        for y in 0..icon.height {
            for x in 0..icon.width {
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
                        imgbuf.put_pixel(x, y, Rgba([icon.red, icon.green, icon.blue, 255]));
                        // Fill with red
                    }
                }
            }
        }
    }

    // Create a temporary file path
    let temp_path = Path::new(path_name);

    println!("Saving icon to {:?}", temp_path);

    // Save the DynamicImage to the temporary file
    imgbuf
        .save(temp_path)
        .map(|_| temp_path.to_path_buf())
        .map_err(|e| format!("Failed to save image to {:?}: {:?}.", temp_path, e))
}
