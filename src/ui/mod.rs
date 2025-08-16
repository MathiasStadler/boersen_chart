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
