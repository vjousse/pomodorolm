#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use clap::Parser;

use clap::Subcommand;

#[derive(Parser)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Adds files to myapp
    Cli,
}

fn main() {
    let cli = Cli::parse();

    // You can check for the existence of subcommands, and if found use their
    // matches just as you would the top level cmd
    match &cli.command {
        Some(command) => match command {
            Commands::Cli => {
                println!("--> CLI mode");
            }
        },
        None => pomodorolm_lib::run(),
    }
}
