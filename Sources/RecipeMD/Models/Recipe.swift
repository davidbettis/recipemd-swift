/// A recipe parsed from or serializable to RecipeMD format.
///
/// `Recipe` is the primary data structure representing a complete recipe.
/// It can be created programmatically or parsed from RecipeMD-formatted Markdown.
///
/// ## Creating a Recipe
///
/// ```swift
/// let recipe = Recipe(
///     title: "Guacamole",
///     description: "A fresh Mexican dip.",
///     tags: ["vegan", "Mexican"],
///     yield: Yield(amount: [
///         Amount(4, unit: "Servings"),
///         Amount(200, unit: "g")
///     ]),
///     ingredientGroups: [
///         IngredientGroup(ingredients: [
///             Ingredient(name: "avocados", amount: Amount(2)),
///             Ingredient(name: "salt", amount: Amount(0.5, unit: "teaspoon"))
///         ])
///     ],
///     instructions: "Mash avocados. Add salt. Serve fresh."
/// )
/// ```
///
/// ## Parsing from Markdown
///
/// ```swift
/// let parser = RecipeMDParser()
/// let recipe = try parser.parse(markdownString)
/// ```
///
/// ## Generating Markdown
///
/// ```swift
/// let generator = RecipeMDGenerator()
/// let markdown = generator.generate(recipe)
/// ```
public struct Recipe: Sendable, Equatable, Codable {
    /// The recipe title (required).
    ///
    /// This corresponds to the level-1 heading in RecipeMD format.
    public var title: String

    /// Optional description paragraphs.
    ///
    /// The description appears between the title and tags/yields in the RecipeMD format.
    /// Multiple paragraphs are separated by blank lines.
    public var description: String?

    /// Recipe tags for categorization.
    ///
    /// Tags are rendered as an italicized comma-separated list (e.g., `*vegan, quick*`).
    /// Common uses include dietary information, cuisine type, or meal category.
    public var tags: [String]

    /// Recipe yield specifying serving sizes or quantities.
    ///
    /// Yield is rendered as a bold comma-separated list (e.g., `**4 Servings, 500g**`).
    /// A single yield can contain multiple amounts for different measurement systems.
    public var yield: Yield

    /// Ingredient groups, optionally with titles.
    ///
    /// Ingredients are organized into groups. Groups can have optional titles
    /// (rendered as headings) for recipes with multiple components like "Crust" and "Filling".
    /// A recipe with no grouped sections has a single group with `title: nil`.
    public var ingredientGroups: [IngredientGroup]

    /// Preparation instructions.
    ///
    /// The instructions section appears after the second `---` divider.
    /// Can contain multiple paragraphs, lists, or other Markdown content.
    public var instructions: String?

    /// Creates a new recipe with the specified properties.
    ///
    /// - Parameters:
    ///   - title: The recipe title (required).
    ///   - description: Optional description text.
    ///   - tags: Tags for categorization. Defaults to empty.
    ///   - yield: Yield specification. Defaults to empty yield.
    ///   - ingredientGroups: Ingredient groups. Defaults to empty.
    ///   - instructions: Preparation instructions.
    public init(
        title: String,
        description: String? = nil,
        tags: [String] = [],
        yield: Yield = Yield(),
        ingredientGroups: [IngredientGroup] = [],
        instructions: String? = nil
    ) {
        self.title = title
        self.description = description
        self.tags = tags
        self.yield = yield
        self.ingredientGroups = ingredientGroups
        self.instructions = instructions
    }
}

// MARK: - Convenience

extension Recipe {
    /// All ingredients across all groups, including nested groups.
    ///
    /// This is a convenience property that flattens all ingredient groups
    /// (including any nested groups) into a single array.
    public var allIngredients: [Ingredient] {
        ingredientGroups.flatMap { $0.allIngredients }
    }

    /// Returns `true` if the recipe has any ingredients.
    public var hasIngredients: Bool {
        !ingredientGroups.isEmpty && ingredientGroups.contains { $0.totalCount > 0 }
    }

    /// Returns `true` if the recipe has instructions.
    public var hasInstructions: Bool {
        instructions != nil && !instructions!.isEmpty
    }
}
