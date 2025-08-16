pub mod ma;
pub mod bollinger;
pub mod rsi;
pub mod macd;

use rust_decimal::Decimal;

pub trait Indicator {
    fn calculate(data: &[Decimal], period: usize) -> Vec<Decimal>;
    fn name(&self) -> &str;
}
