/// One row of the WHO table: the shape of the growth curve at one age.
struct LmsPoint: Equatable {
    /// Age in months since birth.
    let months: Double
    /// Skewness of the distribution.
    let l: Double
    /// Median.
    let m: Double
    /// Coefficient of variation.
    let s: Double
}
