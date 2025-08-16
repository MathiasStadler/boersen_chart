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
