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
