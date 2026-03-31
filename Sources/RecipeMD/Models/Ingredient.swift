/// A single ingredient in a recipe.
///
/// Ingredients can include an optional amount (with unit) and link to another recipe.
///
/// ## RecipeMD Format
///
/// Ingredients are rendered as list items with optional italicized amounts:
/// - `- *2 cups* flour` (amount with unit)
/// - `- *3* eggs` (amount without unit)
/// - `- salt to taste` (no amount)
/// - `- *1 cup* [mayo](mayo.md)` (linked ingredient)
///
/// ## Examples
///
/// ```swift
/// // Simple ingredient
/// let salt = Ingredient(name: "salt")
///
/// // With amount and unit
/// let flour = Ingredient(name: "flour", amount: Amount(2, unit: "cups"))
///
/// // Linked to another recipe
/// let sauce = Ingredient(name: "tomato sauce", amount: Amount(1, unit: "cup"), link: "sauce.md")
/// ```
public struct Ingredient: Sendable, Equatable, Codable {
    /// The ingredient name.
    ///
    /// This is the only required property. Examples: "flour", "large eggs", "olive oil".
    public var name: String

    /// The quantity amount with optional unit.
    ///
    /// Represents numeric quantities like 2, 1.5, or 1/2 with an optional unit.
    /// When present, rendered in italics in RecipeMD format.
    public var amount: Amount?

    /// Optional link to another recipe file.
    ///
    /// Used for ingredients that reference other recipes (e.g., homemade sauces).
    /// Rendered as a Markdown link: `[name](link)`.
    public var link: String?

    /// An alternative amount extracted from non-standard annotations.
    ///
    /// **Extra**: This property is not part of the RecipeMD specification.
    /// It is only populated when the parser's `extractSupplementalAmounts` option
    /// is enabled. For example, `*1 T (15 g)* sugar` would produce a primary
    /// amount of `1 T` and a supplemental amount of `15 g`.
    public var supplementalAmount: Amount?

    /// Creates a new ingredient.
    ///
    /// - Parameters:
    ///   - name: The ingredient name (required).
    ///   - amount: The quantity amount with optional unit.
    ///   - link: URL or path to a linked recipe.
    ///   - supplementalAmount: An alternative amount (extra, not part of the RecipeMD spec).
    public init(
        name: String,
        amount: Amount? = nil,
        link: String? = nil,
        supplementalAmount: Amount? = nil
    ) {
        self.name = name
        self.amount = amount
        self.link = link
        self.supplementalAmount = supplementalAmount
    }
}

// MARK: - Convenience

extension Ingredient {
    /// Returns `true` if this ingredient has an amount specified.
    public var hasAmount: Bool {
        amount != nil
    }

    /// Returns `true` if this ingredient links to another recipe.
    public var isLinked: Bool {
        link != nil
    }

    /// A formatted string representation of the amount and unit.
    ///
    /// Returns `nil` if no amount is set.
    /// Examples: "2 cups", "1/2 teaspoon", "3"
    public var formattedAmount: String? {
        amount?.formatted
    }

    /// A formatted string including the supplemental amount in parentheses.
    ///
    /// **Extra**: Uses the non-spec `supplementalAmount` property.
    /// Returns `nil` if no amount is set. If a supplemental amount is present
    /// it is appended in parentheses, e.g. "1 T (15 g)".
    public var formattedAmountWithSupplemental: String? {
        guard let primary = amount?.formatted else { return nil }
        guard let supplemental = supplementalAmount?.formatted else { return primary }
        return "\(primary) (\(supplemental))"
    }

    /// The ingredient formatted as a RecipeMD list item, with the supplemental
    /// amount included in the italicized amount portion.
    ///
    /// **Extra**: Uses the non-spec `supplementalAmount` property.
    /// Examples:
    /// - `- *1 T (15 g)* sugar`
    /// - `- *2 cups* flour` (no supplemental)
    /// - `- salt` (no amount)
    public var markdownWithSupplemental: String {
        var parts: [String] = []

        if let amountText = formattedAmountWithSupplemental {
            parts.append("*\(amountText)*")
        }

        if let link = link {
            parts.append("[\(name)](\(link))")
        } else {
            parts.append(name)
        }

        return "- \(parts.joined(separator: " "))"
    }
}
