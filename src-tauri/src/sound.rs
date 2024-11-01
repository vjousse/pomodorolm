use crate::{resolve_resource_path, Config};
use rodio::{Decoder, OutputStream, Sink};
use std::fs::File;
use std::io::BufReader;
use std::path::PathBuf;
use tauri::AppHandle;

pub fn get_sound_file<'a>(
    sound_id: &'a str,
    app_handle: &AppHandle,
    config: &'a Config,
) -> Option<PathBuf> {
    match sound_id {
        "audio-long-break" => {
            resolve_resource_path(app_handle, format!("audio/{}", "alert-long-break.mp3")).ok()
        }
        "audio-short-break" => match &config.short_break_audio {
            Some(path) => Some(PathBuf::from(path)),
            None => {
                resolve_resource_path(app_handle, format!("audio/{}", "alert-short-break.mp3")).ok()
            }
        },
        "audio-work" => {
            resolve_resource_path(app_handle, format!("audio/{}", "alert-work.mp3")).ok()
        }
        "audio-tick" => resolve_resource_path(app_handle, format!("audio/{}", "tick.mp3")).ok(),
        _ => None,
    }
}

pub fn play_sound_file(resource_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    // Get a output stream handle to the default physical sound device
    let (_stream, stream_handle) = OutputStream::try_default()?;
    let sink = Sink::try_new(&stream_handle)?;

    // Load a sound from a file, using a path relative to Cargo.toml
    let file = BufReader::new(File::open(resource_path)?);

    // Decode that sound file into a source
    let source = Decoder::new(file)?;
    sink.append(source);
    sink.sleep_until_end();
    Ok(())
}
