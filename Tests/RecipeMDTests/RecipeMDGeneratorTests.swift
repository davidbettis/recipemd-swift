import Testing
@testable import RecipeMD

@Suite("RecipeMDGenerator Tests")
struct RecipeMDGeneratorTests {
    let generator = RecipeMDGenerator()
    let parser = RecipeMDParser()

    // MARK: - Basic Generation

    @Test("Generate simple recipe")
    func generateSimpleRecipe() {
        let recipe = Recipe(
            title: "Guacamole",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "avocado", amount: Amount(1)),
                    Ingredient(name: "salt")
                ])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("# Guacamole"))
        #expect(markdown.contains("---"))
        #expect(markdown.contains("- *1* avocado"))
        #expect(markdown.contains("- salt"))
    }

    @Test("Generate recipe with description")
    func generateWithDescription() {
        let recipe = Recipe(
            title: "Test",
            description: "A delicious recipe.",
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("A delicious recipe."))
    }

    @Test("Generate recipe with tags and yields")
    func generateWithTagsAndYields() {
        let recipe = Recipe(
            title: "Salad",
            tags: ["vegan", "quick"],
            yield: Yield(amount: [Amount(4, unit: "Servings")]),
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "lettuce")
                ])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("*vegan, quick*"))
        #expect(markdown.contains("**4 Servings**"))
    }

    @Test("Generate recipe with multiple yields")
    func generateWithMultipleYields() {
        let recipe = Recipe(
            title: "Recipe",
            yield: Yield(amount: [
                Amount(4, unit: "Servings"),
                Amount(500, unit: "g")
            ]),
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("**4 Servings, 500 g**"))
    }

    @Test("Generate recipe with ingredient groups")
    func generateWithIngredientGroups() {
        let recipe = Recipe(
            title: "Pie",
            ingredientGroups: [
                IngredientGroup(title: "Crust", ingredients: [
                    Ingredient(name: "flour", amount: Amount(2, unit: "cups"))
                ]),
                IngredientGroup(title: "Filling", ingredients: [
                    Ingredient(name: "apples", amount: Amount(4))
                ])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("## Crust"))
        #expect(markdown.contains("## Filling"))
        #expect(markdown.contains("- *2 cups* flour"))
        #expect(markdown.contains("- *4* apples"))
    }

    @Test("Generate recipe with instructions")
    func generateWithInstructions() {
        let recipe = Recipe(
            title: "Toast",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "bread")
                ])
            ],
            instructions: "Toast the bread until golden."
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("Toast the bread until golden."))
        // Should have two --- dividers
        let dividerCount = markdown.components(separatedBy: "---").count - 1
        #expect(dividerCount == 2)
    }

    @Test("Generate recipe with linked ingredient")
    func generateWithLinkedIngredient() {
        let recipe = Recipe(
            title: "Sandwich",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "mayo", link: "mayo.md")
                ])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("- [mayo](mayo.md)"))
    }

    @Test("Generate recipe with linked ingredient and amount")
    func generateWithLinkedIngredientAndAmount() {
        let recipe = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "sauce", amount: Amount(1, unit: "cup"), link: "sauce.md")
                ])
            ]
        )

        let markdown = generator.generate(recipe)

        #expect(markdown.contains("- *1 cup* [sauce](sauce.md)"))
    }

    // MARK: - Generator Options

    @Test("Generate with unicode fractions option")
    func generateWithUnicodeFractions() {
        let recipe = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "flour", amount: Amount(amount: 1.5, unit: "cups", rawText: "1 1/2")),
                    Ingredient(name: "butter", amount: Amount(amount: 0.5, unit: "cup", rawText: "1/2"))
                ])
            ]
        )

        let options = GeneratorOptions(useUnicodeFractions: true)
        let markdown = generator.generate(recipe, options: options)

        #expect(markdown.contains("*1½ cups*"))
        #expect(markdown.contains("*½ cup*"))
    }

    @Test("Generate with custom heading level")
    func generateWithCustomHeadingLevel() {
        let recipe = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(title: "Section", ingredients: [
                    Ingredient(name: "item")
                ])
            ]
        )

        let options = GeneratorOptions(ingredientGroupHeadingLevel: 3)
        let markdown = generator.generate(recipe, options: options)

        #expect(markdown.contains("### Section"))
    }

    @Test("Generate yields with unicode fractions")
    func generateYieldsWithUnicodeFractions() {
        let recipe = Recipe(
            title: "Recipe",
            yield: Yield(amount: [Amount(amount: 1.5, unit: "cups", rawText: "1 1/2")]),
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ]
        )

        let options = GeneratorOptions(useUnicodeFractions: true)
        let markdown = generator.generate(recipe, options: options)

        #expect(markdown.contains("**1½ cups**"))
    }

    // MARK: - Round-Trip Tests

    @Test("Round-trip: simple recipe")
    func roundTripSimpleRecipe() throws {
        let original = Recipe(
            title: "Simple Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "ingredient one"),
                    Ingredient(name: "ingredient two")
                ])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.title == original.title)
        #expect(parsed.ingredientGroups.count == original.ingredientGroups.count)
        #expect(parsed.ingredientGroups[0].ingredients.count == 2)
    }

    @Test("Round-trip: recipe with description")
    func roundTripWithDescription() throws {
        let original = Recipe(
            title: "Recipe",
            description: "A wonderful dish.",
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.description == original.description)
    }

    @Test("Round-trip: recipe with tags and yields")
    func roundTripWithTagsAndYields() throws {
        let original = Recipe(
            title: "Recipe",
            tags: ["vegan", "quick", "healthy"],
            yield: Yield(amount: [Amount(4, unit: "Servings")]),
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.tags == original.tags)
        #expect(parsed.yield.amount.count == original.yield.amount.count)
        #expect(parsed.yield.amount[0].amount == 4.0)
        #expect(parsed.yield.amount[0].unit == "Servings")
    }

    @Test("Round-trip: recipe with ingredient amounts")
    func roundTripWithIngredientAmounts() throws {
        let original = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "flour", amount: Amount(2, unit: "cups")),
                    Ingredient(name: "sugar", amount: Amount(amount: 0.5, unit: "cup", rawText: "1/2"))
                ])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        let ingredients = parsed.ingredientGroups[0].ingredients
        #expect(ingredients[0].name == "flour")
        #expect(ingredients[0].amount?.amount == 2.0)
        #expect(ingredients[0].amount?.unit == "cups")
        #expect(ingredients[1].name == "sugar")
        #expect(ingredients[1].amount?.amount == 0.5)
    }

    @Test("Round-trip: recipe with ingredient groups")
    func roundTripWithIngredientGroups() throws {
        let original = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(title: "Part A", ingredients: [
                    Ingredient(name: "item a")
                ]),
                IngredientGroup(title: "Part B", ingredients: [
                    Ingredient(name: "item b")
                ])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.ingredientGroups.count == 2)
        #expect(parsed.ingredientGroups[0].title == "Part A")
        #expect(parsed.ingredientGroups[1].title == "Part B")
    }

    @Test("Round-trip: recipe with instructions")
    func roundTripWithInstructions() throws {
        let original = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [Ingredient(name: "item")])
            ],
            instructions: "Mix everything together."
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.instructions == original.instructions)
    }

    @Test("Round-trip: complete recipe")
    func roundTripCompleteRecipe() throws {
        let original = Recipe(
            title: "Guacamole",
            description: "A fresh Mexican dip.",
            tags: ["vegan", "Mexican"],
            yield: Yield(amount: [
                Amount(4, unit: "Servings"),
                Amount(200, unit: "g")
            ]),
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "avocados", amount: Amount(2)),
                    Ingredient(name: "salt", amount: Amount(amount: 0.5, unit: "teaspoon", rawText: "1/2")),
                    Ingredient(name: "lime juice")
                ])
            ],
            instructions: "Mash avocados. Add salt and lime juice. Serve fresh."
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        #expect(parsed.title == original.title)
        #expect(parsed.description == original.description)
        #expect(parsed.tags == original.tags)
        #expect(parsed.yield.amount.count == original.yield.amount.count)
        #expect(parsed.ingredientGroups[0].ingredients.count == 3)
        #expect(parsed.instructions == original.instructions)
    }

    @Test("Round-trip: recipe with linked ingredients")
    func roundTripWithLinkedIngredients() throws {
        let original = Recipe(
            title: "Recipe",
            ingredientGroups: [
                IngredientGroup(ingredients: [
                    Ingredient(name: "homemade sauce", amount: Amount(1, unit: "cup"), link: "sauce.md")
                ])
            ]
        )

        let markdown = generator.generate(original)
        let parsed = try parser.parse(markdown)

        let ingredient = parsed.ingredientGroups[0].ingredients[0]
        #expect(ingredient.name == "homemade sauce")
        #expect(ingredient.link == "sauce.md")
        #expect(ingredient.amount?.amount == 1.0)
        #expect(ingredient.amount?.unit == "cup")
    }
}
