/// A group of ingredients, optionally with a title.
///
/// Ingredient groups allow organizing ingredients into sections like "Crust" and "Filling"
/// for complex recipes. Groups with titles are rendered with headings in RecipeMD format.
/// Groups can be nested to create hierarchical ingredient organization.
///
/// ## RecipeMD Format
///
/// ```markdown
/// ## Crust
///
/// - *2 cups* flour
/// - *1 cup* butter
///
/// ## Filling
///
/// - *4* apples
/// - *1 cup* sugar
///
/// ### Topping
///
/// - *1/2 cup* brown sugar
/// ```
///
/// ## Examples
///
/// ```swift
/// // Untitled group (most common)
/// let ingredients = IngredientGroup(ingredients: [
///     Ingredient(name: "flour", amount: Amount(2, unit: "cups")),
///     Ingredient(name: "sugar", amount: Amount(1, unit: "cup"))
/// ])
///
/// // Named group for multi-part recipes
/// let crust = IngredientGroup(title: "Crust", ingredients: [
///     Ingredient(name: "flour", amount: Amount(2, unit: "cups"))
/// ])
///
/// // Nested groups
/// let filling = IngredientGroup(
///     title: "Filling",
///     ingredients: [Ingredient(name: "apples", amount: Amount(4))],
///     ingredientGroups: [
///         IngredientGroup(title: "Topping", ingredients: [...])
///     ]
/// )
/// ```
public struct IngredientGroup: Sendable, Equatable, Codable {
    /// Optional group title.
    ///
    /// When present, rendered as a heading (default: `##`) in the ingredients section.
    /// Use for recipes with distinct components like pie crust and filling.
    public var title: String?

    /// Ingredients in this group.
    public var ingredients: [Ingredient]

    /// Nested ingredient groups.
    ///
    /// Allows hierarchical organization of ingredients. Nested groups are rendered
    /// with incrementing heading levels (e.g., `###` for groups nested under `##`).
    public var ingredientGroups: [IngredientGroup]

    /// Creates a new ingredient group.
    ///
    /// - Parameters:
    ///   - title: Optional group title.
    ///   - ingredients: The ingredients in this group.
    ///   - ingredientGroups: Nested ingredient groups.
    public init(
        title: String? = nil,
        ingredients: [Ingredient] = [],
        ingredientGroups: [IngredientGroup] = []
    ) {
        self.title = title
        self.ingredients = ingredients
        self.ingredientGroups = ingredientGroups
    }
}

// MARK: - Convenience

extension IngredientGroup {
    /// Returns `true` if this group has a title.
    public var hasTitle: Bool {
        title != nil && !title!.isEmpty
    }

    /// Returns `true` if this group contains any ingredients (not including nested groups).
    public var hasIngredients: Bool {
        !ingredients.isEmpty
    }

    /// The number of ingredients in this group (not including nested groups).
    public var count: Int {
        ingredients.count
    }

    /// Returns `true` if this group has any nested ingredient groups.
    public var hasNestedGroups: Bool {
        !ingredientGroups.isEmpty
    }

    /// The total number of ingredients including all nested groups.
    public var totalCount: Int {
        ingredients.count + ingredientGroups.reduce(0) { $0 + $1.totalCount }
    }

    /// All ingredients from this group and all nested groups, flattened.
    public var allIngredients: [Ingredient] {
        ingredients + ingredientGroups.flatMap { $0.allIngredients }
    }
}
