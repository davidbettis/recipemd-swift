/// A numeric amount for an ingredient or yield.
///
/// `Amount` stores both the numeric value, optional unit, and the original text representation,
/// allowing preservation of the user's preferred format (fractions, decimals, etc.).
///
/// ## Supported Formats
///
/// - Integers: `2`, `10`
/// - Decimals: `1.5`, `0.25`
/// - Fractions: `1/2`, `3/4`
/// - Mixed numbers: `1 1/2`, `2 3/4`
/// - Unicode fractions: `½`, `¾`, `1½`
/// - European decimals: `1,5` (comma as decimal separator)
///
/// ## Examples
///
/// ```swift
/// // From integer
/// let two = Amount(2)  // amount: 2.0, rawText: "2"
///
/// // From double
/// let half = Amount(0.5)  // amount: 0.5, rawText: "0.5"
///
/// // With unit
/// let flour = Amount(amount: 2.0, unit: "cups", rawText: "2")
///
/// // Preserving original format
/// let fraction = Amount(amount: 0.5, rawText: "1/2")
/// let mixed = Amount(amount: 1.5, rawText: "1 1/2")
/// ```
public struct Amount: Sendable, Equatable, Codable {
    /// The numeric value.
    ///
    /// This is the computed decimal value regardless of the original format.
    /// For example, both "1/2" and "0.5" result in `amount: 0.5`.
    public var amount: Double

    /// The unit of measurement.
    ///
    /// Common units include: "cups", "tablespoons", "g", "oz", "ml".
    /// May be nil for unitless amounts (e.g., "2 eggs").
    public var unit: String?

    /// The original text representation.
    ///
    /// Preserves the user's preferred format for display and round-tripping.
    /// Examples: "2", "1.5", "1/2", "1 1/2", "½"
    public var rawText: String

    /// Creates an Amount with explicit value, unit, and text representation.
    ///
    /// Use this initializer when you need to preserve a specific text format.
    ///
    /// - Parameters:
    ///   - amount: The numeric value.
    ///   - unit: The unit of measurement (optional).
    ///   - rawText: The original text representation.
    public init(amount: Double, unit: String? = nil, rawText: String) {
        self.amount = amount
        self.unit = unit
        self.rawText = rawText
    }

    /// Creates an Amount from an integer.
    ///
    /// - Parameters:
    ///   - value: The integer value.
    ///   - unit: The unit of measurement (optional).
    public init(_ value: Int, unit: String? = nil) {
        self.amount = Double(value)
        self.unit = unit
        self.rawText = String(value)
    }

    /// Creates an Amount from a double.
    ///
    /// The `rawText` is automatically formatted: whole numbers omit decimals,
    /// others use standard decimal notation.
    ///
    /// - Parameters:
    ///   - value: The double value.
    ///   - unit: The unit of measurement (optional).
    public init(_ value: Double, unit: String? = nil) {
        self.amount = value
        self.unit = unit
        self.rawText = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }
}

// MARK: - Convenience

extension Amount {
    /// Returns `true` if the amount is a whole number.
    public var isWholeNumber: Bool {
        amount.truncatingRemainder(dividingBy: 1) == 0
    }

    /// The amount as an integer, if it's a whole number.
    public var intValue: Int? {
        isWholeNumber ? Int(amount) : nil
    }

    /// A formatted string representation of the amount and unit.
    ///
    /// Returns the raw text with unit appended if present.
    /// Examples: "2 cups", "1/2 teaspoon", "3"
    public var formatted: String {
        if let unit = unit {
            return "\(rawText) \(unit)"
        }
        return rawText
    }

    /// Creates an Amount from a fraction.
    ///
    /// - Parameters:
    ///   - numerator: The numerator.
    ///   - denominator: The denominator.
    ///   - unit: The unit of measurement (optional).
    /// - Returns: An Amount representing the fraction, or `nil` if denominator is zero.
    public static func fraction(_ numerator: Int, _ denominator: Int, unit: String? = nil) -> Amount? {
        guard denominator != 0 else { return nil }
        let value = Double(numerator) / Double(denominator)
        return Amount(amount: value, unit: unit, rawText: "\(numerator)/\(denominator)")
    }

    /// Creates an Amount from a mixed number.
    ///
    /// - Parameters:
    ///   - whole: The whole number part.
    ///   - numerator: The fraction numerator.
    ///   - denominator: The fraction denominator.
    ///   - unit: The unit of measurement (optional).
    /// - Returns: An Amount representing the mixed number, or `nil` if denominator is zero.
    public static func mixed(_ whole: Int, _ numerator: Int, _ denominator: Int, unit: String? = nil) -> Amount? {
        guard denominator != 0 else { return nil }
        let value = Double(whole) + Double(numerator) / Double(denominator)
        return Amount(amount: value, unit: unit, rawText: "\(whole) \(numerator)/\(denominator)")
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Amount: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

// MARK: - ExpressibleByFloatLiteral

extension Amount: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}
