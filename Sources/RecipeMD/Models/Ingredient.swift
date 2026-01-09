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

    /// Creates a new ingredient.
    ///
    /// - Parameters:
    ///   - name: The ingredient name (required).
    ///   - amount: The quantity amount with optional unit.
    ///   - link: URL or path to a linked recipe.
    public init(
        name: String,
        amount: Amount? = nil,
        link: String? = nil
    ) {
        self.name = name
        self.amount = amount
        self.link = link
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
}
