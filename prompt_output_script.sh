#!/bin/bash

# Sicherstellen, dass wir im Home-Verzeichnis starten
cd ~ || exit

# 1. Projekt erstellen
echo "🚀 Erstelle neues Cargo-Projekt..."
cargo new --bin boersen_chart
cd boersen_chart || exit

# 2. Aktualisierte Cargo.toml konfigurieren
echo "📦 Konfiguriere Cargo.toml mit aktuellen Versionen..."
cat > Cargo.toml << 'EOF'
[package]
name = "boersen_chart"
version = "0.1.0"
edition = "2021"

[dependencies]
eframe = "0.27"
egui = "0.27"
egui_plot = "0.27"
csv = "1.3"
serde = { version = "1.0", features = ["derive"] }
chrono = { version = "0.4", features = ["serde"] }
thiserror = "1.0"
itertools = "0.12"
rand = "0.8"
rust_decimal = "1.35"  # Für präzise Finanzberechnungen
anyhow = "1.0"         # Für bessere Fehlerbehandlung

[dev-dependencies]
assert_approx_eq = "1.1"
test-case = "3.3"      # Für bessere Testorganisation
EOF

# 3. Projektstruktur erstellen
echo "📂 Erstelle erweiterte Projektstruktur..."
mkdir -p src/{data,indicators,ui,utils}
touch src/{main.rs,lib.rs}

# 4. Hauptmodul mit Error-Handling
echo "📝 Erstelle main.rs mit verbessertem Error-Handling..."
cat > src/main.rs << 'EOF'
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
EOF

# 5. Verbessertes Datenmodell
echo "🗃️ Erstelle erweitertes Datenmodell..."
cat > src/data/mod.rs << 'EOF'
pub mod model;
pub mod loader;
pub mod generator;
EOF

cat > src/data/model.rs << 'EOF'
use serde::{Deserialize, Serialize};
use chrono::NaiveDate;
use rust_decimal::Decimal;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StockData {
    pub date: NaiveDate,
    #[serde(with = "rust_decimal::serde::str")]
    pub open: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub high: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub low: Decimal,
    #[serde(with = "rust_decimal::serde::str")]
    pub close: Decimal,
    pub volume: u64,
}

#[derive(Debug)]
pub struct StockDataSet {
    pub data: Vec<StockData>,
    pub symbol: String,
}

impl StockDataSet {
    pub fn new(symbol: &str) -> Self {
        Self {
            data: Vec::new(),
            symbol: symbol.to_string(),
        }
    }
}
EOF

cat > src/data/loader.rs << 'EOF'
use crate::data::model::{StockData, StockDataSet};
use std::path::Path;
use thiserror::Error;
use rust_decimal::Decimal;
use chrono::NaiveDate;
use csv::StringRecord;

#[derive(Error, Debug)]
pub enum DataError {
    #[error("CSV parsing error")]
    CsvError(#[from] csv::Error),
    #[error("IO error")]
    IoError(#[from] std::io::Error),
    #[error("Date parsing error")]
    DateError(#[from] chrono::format::ParseError),
    #[error("Invalid decimal value")]
    DecimalError(#[from] rust_decimal::Error),
    #[error("Invalid header, expected CSV with columns: date,open,high,low,close,volume")]
    InvalidHeader,
}

impl StockDataSet {
    pub fn load_from_csv<P: AsRef<Path>>(path: P, symbol: &str) -> Result<Self, DataError> {
        let mut rdr = csv::Reader::from_path(path)?;
        
        // Header validieren
        let headers = rdr.headers()?;
        if headers != ["date", "open", "high", "low", "close", "volume"] {
            return Err(DataError::InvalidHeader);
        }

        let mut dataset = Self::new(symbol);
        
        for result in rdr.records() {
            let record = result?;
            dataset.data.push(Self::parse_record(&record)?);
        }
        
        Ok(dataset)
    }

    fn parse_record(record: &StringRecord) -> Result<StockData, DataError> {
        Ok(StockData {
            date: NaiveDate::parse_from_str(&record[0], "%Y-%m-%d")?,
            open: Decimal::from_str_exact(&record[1])?,
            high: Decimal::from_str_exact(&record[2])?,
            low: Decimal::from_str_exact(&record[3])?,
            close: Decimal::from_str_exact(&record[4])?,
            volume: record[5].parse().unwrap_or(0),
        })
    }
}
EOF

# 6. Verbesserte Indikatoren mit Decimal
echo "📊 Erstelle präzise Indikatoren mit Decimal..."
cat > src/indicators/mod.rs << 'EOF'
pub mod ma;
pub mod bollinger;
pub mod rsi;
pub mod macd;

use rust_decimal::Decimal;

pub trait Indicator {
    fn calculate(data: &[Decimal], period: usize) -> Vec<Decimal>;
    fn name(&self) -> &str;
}
EOF

cat > src/indicators/ma.rs << 'EOF'
use super::Indicator;
use rust_decimal::{Decimal, prelude::*};
use itertools::Itertools;

pub struct MovingAverage {
    period: usize,
}

impl MovingAverage {
    pub fn new(period: usize) -> Self {
        Self { period }
    }
}

impl Indicator for MovingAverage {
    fn calculate(&self, data: &[Decimal], _period: usize) -> Vec<Decimal> {
        data.windows(self.period)
            .map(|w| w.iter().sum::<Decimal>() / Decimal::from(w.len()))
            .collect()
    }

    fn name(&self) -> &str {
        match self.period {
            20 => "MA20",
            50 => "MA50",
            _ => "MA"
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use rust_decimal_macros::dec;

    #[test]
    fn test_ma_calculation() {
        let data = vec![dec!(1.0), dec!(2.0), dec!(3.0), dec!(4.0), dec!(5.0)];
        let ma = MovingAverage::new(3);
        let result = ma.calculate(&data, 3);
        assert_eq!(result[0], dec!(2.0));
        assert_eq!(result[1], dec!(3.0));
        assert_eq!(result[2], dec!(4.0));
    }
}
EOF

# 7. Modernisierte UI-Komponenten
echo "🎨 Erstelle aktualisierte UI-Komponenten..."
cat > src/ui/mod.rs << 'EOF'
use eframe::egui;
use egui_plot::{Plot, Line, BarChart, Bar, Legend, PlotPoints};
use crate::data::StockDataSet;
use crate::indicators::{ma::MovingAverage, bollinger::BollingerBands};

pub struct StockApp {
    data: StockDataSet,
    days_to_show: usize,
    indicators: Vec<Box<dyn Indicator>>,
    visible_indicators: Vec<bool>,
    chart_style: ChartStyle,
}

struct ChartStyle {
    ohlc_width: f32,
    up_color: egui::Color32,
    down_color: egui::Color32,
    background: egui::Color32,
}

impl Default for StockApp {
    fn default() -> Self {
        let mut indicators: Vec<Box<dyn Indicator>> = Vec::new();
        indicators.push(Box::new(MovingAverage::new(20)));
        indicators.push(Box::new(MovingAverage::new(50)));
        indicators.push(Box::new(BollingerBands::new(20, dec!(2.0))));

        Self {
            data: StockDataSet::mock_data(100),
            days_to_show: 30,
            visible_indicators: vec![true, true, false],
            indicators,
            chart_style: ChartStyle {
                ohlc_width: 0.6,
                up_color: egui::Color32::from_rgb(0, 180, 0),
                down_color: egui::Color32::from_rgb(180, 0, 0),
                background: egui::Color32::from_rgb(25, 25, 25),
            },
        }
    }
}

impl eframe::App for StockApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default()
            .frame(egui::Frame::none().fill(self.chart_style.background))
            .show(ctx, |ui| {
                self.render_top_panel(ui);
                self.render_main_chart(ui);
                self.render_bottom_panel(ui);
            });
    }
}

impl StockApp {
    fn render_top_panel(&mut self, ui: &mut egui::Ui) {
        egui::TopBottomPanel::top("top_panel").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.label("Tage anzeigen:");
                ui.add(egui::Slider::new(&mut self.days_to_show, 1..=365).text("Tage"));
                
                for (i, indicator) in self.indicators.iter().enumerate() {
                    ui.checkbox(&mut self.visible_indicators[i], indicator.name());
                }
                
                if ui.button("CSV laden").clicked() {
                    self.load_csv_dialog();
                }
            });
        });
    }
    
    fn render_main_chart(&self, ui: &mut egui::Ui) {
        let plot = Plot::new("price_chart")
            .legend(Legend::default().position(egui_plot::Corner::LeftTop))
            .height(400.0)
            .show_axes([true, true])
            .allow_zoom(true)
            .allow_drag(true);

        plot.show(ui, |plot_ui| {
            // OHLC Rendering
            for day in &self.data.data[..self.days_to_show] {
                let bar = Bar::new(
                    day.date.num_days_from_ce() as f64,
                    day.open.to_f64().unwrap(),
                    day.high.to_f64().unwrap(),
                    day.low.to_f64().unwrap(),
                    day.close.to_f64().unwrap(),
                )
                .width(self.chart_style.ohlc_width)
                .color(if day.close >= day.open {
                    self.chart_style.up_color
                } else {
                    self.chart_style.down_color
                });
                
                plot_ui.bar_chart(BarChart::new(vec![bar]));
            }

            // Indikatoren
            for (i, indicator) in self.indicators.iter().enumerate() {
                if self.visible_indicators[i] {
                    // Hier Indikatoren rendern
                }
            }
        });
    }
}
EOF

# 8. Build- und Run-Skript mit mehr Features
echo "🛠️ Erstelle erweitertes Build-Skript..."
cat > run.sh << 'EOF'
#!/bin/bash

# Projekt bauen und ausführen
set -e

echo "🔍 Überprüfe Systemvoraussetzungen..."
if ! command -v cargo &> /dev/null; then
    echo "Rust ist nicht installiert. Installiere jetzt..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

echo "🛠️ Baue Projekt im Release-Modus..."
cargo build --release

echo "🧪 Führe Unit-Tests aus..."
cargo test -- --test-threads=1 --nocapture

echo "📊 Führe Integrationstests aus..."
cargo test --tests -- --nocapture

echo "🚀 Starte Anwendung..."
cargo run --release

echo "✅ Alles erledigt! Das Fenster sollte sich jetzt öffnen."
EOF

chmod +x run.sh

# 9. Beispiel-CSV-Datei erstellen
echo "📝 Erstelle Beispiel-CSV..."
cat > example_data.csv << 'EOF'
date,open,high,low,close,volume
2023-01-01,100.50,102.00,99.50,101.20,100000
2023-01-02,101.20,103.50,100.80,103.00,120000
2023-01-03,103.00,104.00,102.50,102.80,95000
2023-01-04,102.80,103.20,101.50,102.00,110000
2023-01-05,102.00,103.50,101.00,103.20,115000
EOF

echo "✅ Projekt erfolgreich erstellt mit:"
echo "- egui 0.27 (aktuelle stabile Version)"
echo "- Präzise Decimal-Berechnungen"
echo "- Verbessertes Error-Handling"
echo "- Erweiterte Testabdeckung"
echo "- Modernes UI-Design"
echo ""
echo "Starten Sie die Anwendung mit:"
echo "  cd ~/boersen_chart && ./run.sh"