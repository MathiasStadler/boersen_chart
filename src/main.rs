use eframe::{egui, NativeOptions};
use anyhow::Result;

mod data;
mod indicators;
mod ui;
mod utils;

fn main() -> Result<()> {
    let options = NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([1200.0, 800.0])
            .with_title("Börsenchart Analysetool v0.1"),
        ..Default::default()
    };

    eframe::run_native(
        "Börsenchart",
        options,
        Box::new(|cc| {
            Box::new(ui::StockApp::new(cc))
        }),
    ).map_err(|e| anyhow::anyhow!("Application error: {}", e))?;

    Ok(())
}
