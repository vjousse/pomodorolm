use rodio::{Decoder, DeviceSinkBuilder};
use std::fs::File;
use std::io::BufReader;

pub fn play_sound_file(resource_path: &str, volume: f32) -> Result<(), Box<dyn std::error::Error>> {
    // Get a output stream handle to the default physical sound device
    let mut stream_handle = DeviceSinkBuilder::open_default_sink()?;
    stream_handle.log_on_drop(false);
    let player = rodio::Player::connect_new(stream_handle.mixer());
    player.set_volume(volume);

    // Load a sound from a file, using a path relative to Cargo.toml
    let file = BufReader::new(File::open(resource_path)?);

    // Decode that sound file into a source
    let source = Decoder::try_from(file)?;
    player.append(source);
    player.sleep_until_end();
    Ok(())
}
