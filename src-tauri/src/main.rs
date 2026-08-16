#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
use clap::Parser;
use clap::Subcommand;

use anyhow::Result;

#[derive(Parser)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the CLI version of the app
    Cli {
        /// Display current session label after the timer
        #[arg(short, long, default_value_t = false)]
        display_label: bool,
    },
}

const CONFIG_DIR_NAME: &str = "pomodorolm";

fn main() -> Result<()> {
    let cli = Cli::parse();

    // You can check for the existence of subcommands, and if found use their
    // matches just as you would the top level cmd
    match &cli.command {
        Some(command) => match command {
            Commands::Cli { display_label } => {
                pomodorolm_lib::cli::run(CONFIG_DIR_NAME, *display_label)
            }
        },
        None => pomodorolm_lib::run_gui(CONFIG_DIR_NAME),
    }
}
