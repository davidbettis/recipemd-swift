/// A yield specification for a recipe.
///
/// Yield indicates how much a recipe makes, containing one or more amounts
/// such as number of servings and/or total weight.
///
/// ## RecipeMD Format
///
/// Yields are rendered as a bold comma-separated list:
/// ```markdown
/// **4 Servings, 500 g**
/// ```
///
/// ## Examples
///
/// ```swift
/// // Single amount
/// let yield = Yield(amount: [Amount(4, unit: "Servings")])
///
/// // Multiple amounts
/// let yield = Yield(amount: [
///     Amount(4, unit: "Servings"),
///     Amount(500, unit: "g")
/// ])
/// ```
public struct Yield: Sendable, Equatable, Codable {
    /// The amounts in this yield specification.
    ///
    /// A yield can contain multiple amounts, such as both servings and weight.
    public var amount: [Amount]

    /// Creates a new yield.
    ///
    /// - Parameter amount: The yield amounts.
    public init(amount: [Amount] = []) {
        self.amount = amount
    }
}

// MARK: - Convenience

extension Yield {
    /// Creates a yield for a number of servings.
    ///
    /// - Parameter count: The number of servings.
    /// - Returns: A Yield with a single "Servings" amount.
    public static func servings(_ count: Int) -> Yield {
        Yield(amount: [Amount(count, unit: "Servings")])
    }

    /// Creates a yield for a weight in grams.
    ///
    /// - Parameter grams: The weight in grams.
    /// - Returns: A Yield with a single "g" amount.
    public static func grams(_ grams: Int) -> Yield {
        Yield(amount: [Amount(grams, unit: "g")])
    }

    /// Creates a yield for a weight in ounces.
    ///
    /// - Parameter ounces: The weight in ounces.
    /// - Returns: A Yield with a single "oz" amount.
    public static func ounces(_ ounces: Double) -> Yield {
        Yield(amount: [Amount(ounces, unit: "oz")])
    }

    /// A formatted string representation of all amounts.
    ///
    /// Examples: "4 Servings", "4 Servings, 500 g", "12"
    public var formatted: String {
        amount.map { $0.formatted }.joined(separator: ", ")
    }

    /// Returns `true` if this yield has any amounts.
    public var hasAmounts: Bool {
        !amount.isEmpty
    }
}
