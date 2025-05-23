extern crate dirs;
use crate::config::Config;

pub fn run(config_dir_name: &str) {
    println!("--> [cli] run `{}`", config_dir_name);

    let config_dir = dirs::config_dir()
        .expect("Error while getting the config directory")
        .join(config_dir_name);

    let config = Config::get_or_create_from_disk(&config_dir, None);

    println!("{:#?}", config);
}
