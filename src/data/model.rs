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
