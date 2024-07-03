use rodio::{Decoder, OutputStream, Sink};
use std::fs::File;
use std::io::BufReader;

pub fn get_sound_file(sound_id: &str) -> Option<&str> {
    match sound_id {
        "audio-long-break" => Some("alert-long-break.mp3"),
        "audio-short-break" => Some("alert-short-break.mp3"),
        "audio-work" => Some("alert-work.mp3"),
        "audio-tick" => Some("tick.mp3"),
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
