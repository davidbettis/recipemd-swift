import Testing
@testable import RecipeMD

@Suite("RecipeMDParser Tests")
struct RecipeMDParserTests {
    let parser = RecipeMDParser()

    // MARK: - Title Parsing

    @Test("Parse simple recipe title")
    func parseSimpleTitle() throws {
        let markdown = """
        # Guacamole

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.title == "Guacamole")
    }

    @Test("Throws error for missing title")
    func missingTitle() {
        let markdown = """
        Some text without a title.

        ---

        - ingredient
        """

        #expect(throws: RecipeMDError.missingTitle) {
            try parser.parse(markdown)
        }
    }

    @Test("Throws error for missing ingredient section")
    func missingIngredientSection() {
        let markdown = """
        # Recipe Title

        Just some text without a divider.
        """

        #expect(throws: RecipeMDError.missingIngredientSection) {
            try parser.parse(markdown)
        }
    }

    // MARK: - Description Parsing

    @Test("Parse recipe with description")
    func parseDescription() throws {
        let markdown = """
        # Guacamole

        A delicious avocado-based dip.

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.description == "A delicious avocado-based dip.")
    }

    @Test("Parse recipe with multi-paragraph description")
    func parseMultiParagraphDescription() throws {
        let markdown = """
        # Guacamole

        A delicious avocado-based dip.

        Perfect for parties and gatherings.

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.description == "A delicious avocado-based dip.\n\nPerfect for parties and gatherings.")
    }

    @Test("Parse recipe without description")
    func parseNoDescription() throws {
        let markdown = """
        # Guacamole

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.description == nil)
    }

    // MARK: - Ingredient Parsing

    @Test("Parse simple ingredient list")
    func parseSimpleIngredients() throws {
        let markdown = """
        # Recipe

        ---

        - avocado
        - salt
        - lime juice
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.ingredientGroups.count == 1)
        #expect(recipe.ingredientGroups[0].ingredients.count == 3)
        #expect(recipe.ingredientGroups[0].ingredients[0].name == "avocado")
        #expect(recipe.ingredientGroups[0].ingredients[1].name == "salt")
        #expect(recipe.ingredientGroups[0].ingredients[2].name == "lime juice")
    }

    @Test("Parse ingredient with integer amount")
    func parseIngredientWithIntegerAmount() throws {
        let markdown = """
        # Recipe

        ---

        - *2* eggs
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.name == "eggs")
        #expect(ingredient.amount?.amount == 2.0)
        #expect(ingredient.amount?.rawText == "2")
        #expect(ingredient.amount?.unit == nil)
    }

    @Test("Parse ingredient with amount and unit")
    func parseIngredientWithAmountAndUnit() throws {
        let markdown = """
        # Recipe

        ---

        - *2 cups* flour
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.name == "flour")
        #expect(ingredient.amount?.amount == 2.0)
        #expect(ingredient.amount?.unit == "cups")
    }

    @Test("Parse ingredient with decimal amount")
    func parseIngredientWithDecimalAmount() throws {
        let markdown = """
        # Recipe

        ---

        - *1.5 cups* sugar
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 1.5)
        #expect(ingredient.amount?.rawText == "1.5")
    }

    @Test("Parse ingredient with fraction amount")
    func parseIngredientWithFractionAmount() throws {
        let markdown = """
        # Recipe

        ---

        - *1/2 cup* milk
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 0.5)
        #expect(ingredient.amount?.rawText == "1/2")
        #expect(ingredient.amount?.unit == "cup")
    }

    @Test("Parse ingredient with mixed fraction amount")
    func parseIngredientWithMixedFractionAmount() throws {
        let markdown = """
        # Recipe

        ---

        - *1 1/2 cups* flour
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 1.5)
        #expect(ingredient.amount?.rawText == "1 1/2")
        #expect(ingredient.amount?.unit == "cups")
    }

    @Test("Parse ingredient with unicode fraction")
    func parseIngredientWithUnicodeFraction() throws {
        let markdown = """
        # Recipe

        ---

        - *½ cup* butter
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 0.5)
        #expect(ingredient.amount?.rawText == "½")
        #expect(ingredient.amount?.unit == "cup")
    }

    @Test("Parse ingredient with mixed unicode fraction")
    func parseIngredientWithMixedUnicodeFraction() throws {
        let markdown = """
        # Recipe

        ---

        - *1½ cups* flour
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 1.5)
        #expect(ingredient.amount?.unit == "cups")
    }

    @Test("Parse ingredient with mixed unicode quarter fraction")
    func parseIngredientWithMixedUnicodeQuarterFraction() throws {
        let markdown = """
        # Recipe

        ---

        - *1¼ cups* flour
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 1.25)
        #expect(ingredient.amount?.unit == "cups")
    }

    @Test("Parse ingredient with comma decimal separator")
    func parseIngredientWithCommaDecimal() throws {
        let markdown = """
        # Recipe

        ---

        - *1,5 kg* potatoes
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.amount?.amount == 1.5)
        #expect(ingredient.amount?.unit == "kg")
    }

    @Test("Parse ingredient with link")
    func parseIngredientWithLink() throws {
        let markdown = """
        # Recipe

        ---

        - *1 cup* [homemade mayo](mayo.md)
        """

        let recipe = try parser.parse(markdown)
        let ingredient = recipe.ingredientGroups[0].ingredients[0]
        #expect(ingredient.name == "homemade mayo")
        #expect(ingredient.link == "mayo.md")
        #expect(ingredient.amount?.amount == 1.0)
        #expect(ingredient.amount?.unit == "cup")
    }

    // MARK: - Ingredient Groups

    @Test("Parse ingredient groups with headings")
    func parseIngredientGroups() throws {
        let markdown = """
        # Pie

        ---

        ## Crust

        - *2 cups* flour
        - *1 cup* butter

        ## Filling

        - *4* apples
        - *1 cup* sugar
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.ingredientGroups.count == 2)

        #expect(recipe.ingredientGroups[0].title == "Crust")
        #expect(recipe.ingredientGroups[0].ingredients.count == 2)

        #expect(recipe.ingredientGroups[1].title == "Filling")
        #expect(recipe.ingredientGroups[1].ingredients.count == 2)
    }

    @Test("Parse mixed groups with and without titles")
    func parseMixedIngredientGroups() throws {
        let markdown = """
        # Recipe

        ---

        - *1* base ingredient

        ## Special Section

        - *2* special ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.ingredientGroups.count == 2)
        #expect(recipe.ingredientGroups[0].title == nil)
        #expect(recipe.ingredientGroups[0].ingredients[0].name == "base ingredient")
        #expect(recipe.ingredientGroups[1].title == "Special Section")
    }

    // MARK: - Instructions Parsing

    @Test("Parse recipe with instructions")
    func parseInstructions() throws {
        let markdown = """
        # Toast

        ---

        - bread

        ---

        Toast the bread until golden brown.
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.instructions == "Toast the bread until golden brown.")
    }

    @Test("Parse recipe with multi-paragraph instructions")
    func parseMultiParagraphInstructions() throws {
        let markdown = """
        # Recipe

        ---

        - ingredient

        ---

        First, prepare the ingredients.

        Then, cook everything together.
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.instructions == "First, prepare the ingredients.\n\nThen, cook everything together.")
    }

    @Test("Parse recipe without instructions")
    func parseNoInstructions() throws {
        let markdown = """
        # Recipe

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.instructions == nil)
    }

    @Test("Parse instructions with ordered list")
    func parseInstructionsWithOrderedList() throws {
        let markdown = """
        # Recipe

        ---

        - ingredient

        ---

        1. Step one
        2. Step two
        3. Step three
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.instructions?.contains("1. Step one") == true)
        #expect(recipe.instructions?.contains("2. Step two") == true)
        #expect(recipe.instructions?.contains("3. Step three") == true)
    }

    // MARK: - Tags Parsing

    @Test("Parse recipe with tags")
    func parseTags() throws {
        let markdown = """
        # Guacamole

        *vegan, gluten-free, quick*

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.tags == ["vegan", "gluten-free", "quick"])
    }

    @Test("Parse recipe with single tag")
    func parseSingleTag() throws {
        let markdown = """
        # Recipe

        *vegetarian*

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.tags == ["vegetarian"])
    }

    @Test("Parse recipe without tags")
    func parseNoTags() throws {
        let markdown = """
        # Recipe

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.tags.isEmpty)
    }

    @Test("Parse tags with description")
    func parseTagsWithDescription() throws {
        let markdown = """
        # Recipe

        A tasty dish.

        *healthy, easy*

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.description == "A tasty dish.")
        #expect(recipe.tags == ["healthy", "easy"])
    }

    // MARK: - Yields Parsing

    @Test("Parse recipe with yields")
    func parseYields() throws {
        let markdown = """
        # Recipe

        **4 Servings**

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.yield.amount.count == 1)
        #expect(recipe.yield.amount[0].amount == 4.0)
        #expect(recipe.yield.amount[0].unit == "Servings")
    }

    @Test("Parse recipe with multiple yields")
    func parseMultipleYields() throws {
        let markdown = """
        # Recipe

        **4 Servings, 500g**

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.yield.amount.count == 2)
        #expect(recipe.yield.amount[0].amount == 4.0)
        #expect(recipe.yield.amount[0].unit == "Servings")
        #expect(recipe.yield.amount[1].amount == 500.0)
        #expect(recipe.yield.amount[1].unit == "g")
    }

    @Test("Parse yields with fractions")
    func parseYieldsWithFractions() throws {
        let markdown = """
        # Recipe

        **1 1/2 cups**

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.yield.amount.count == 1)
        #expect(recipe.yield.amount[0].amount == 1.5)
        #expect(recipe.yield.amount[0].unit == "cups")
    }

    @Test("Parse recipe without yields")
    func parseNoYields() throws {
        let markdown = """
        # Recipe

        ---

        - ingredient
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.yield.amount.isEmpty)
    }

    @Test("Parse tags and yields together")
    func parseTagsAndYields() throws {
        let markdown = """
        # Guacamole

        A delicious dip.

        *vegan, Mexican*
        **4 Servings, 200g**

        ---

        - avocado
        """

        let recipe = try parser.parse(markdown)
        #expect(recipe.description == "A delicious dip.")
        #expect(recipe.tags == ["vegan", "Mexican"])
        #expect(recipe.yield.amount.count == 2)
        #expect(recipe.yield.amount[0].amount == 4.0)
        #expect(recipe.yield.amount[1].amount == 200.0)
    }

    // MARK: - Full Recipe Parsing

    @Test("Parse complete recipe")
    func parseCompleteRecipe() throws {
        let markdown = """
        # Guacamole

        A delicious Mexican dip made with ripe avocados.

        ---

        - *2* ripe avocados
        - *1/2 teaspoon* salt
        - *1 tablespoon* lime juice
        - *2 tablespoons* onion, minced

        ---

        Mash avocados in a bowl. Add salt and lime juice, mix well.
        Fold in onion. Serve immediately.
        """

        let recipe = try parser.parse(markdown)

        #expect(recipe.title == "Guacamole")
        #expect(recipe.description == "A delicious Mexican dip made with ripe avocados.")
        #expect(recipe.ingredientGroups.count == 1)
        #expect(recipe.ingredientGroups[0].ingredients.count == 4)
        #expect(recipe.instructions?.contains("Mash avocados") == true)
    }

    @Test("Parse complete recipe with tags and yields")
    func parseCompleteRecipeWithTagsAndYields() throws {
        let markdown = """
        # Guacamole

        A delicious Mexican dip.

        *vegan, gluten-free*
        **4 Servings**

        ---

        - *2* avocados
        - *½ teaspoon* salt
        - lemon juice

        ---

        Mash avocados, add salt and lemon juice. Serve fresh.
        """

        let recipe = try parser.parse(markdown)

        #expect(recipe.title == "Guacamole")
        #expect(recipe.description == "A delicious Mexican dip.")
        #expect(recipe.tags == ["vegan", "gluten-free"])
        #expect(recipe.yield.amount.count == 1)
        #expect(recipe.yield.amount[0].amount == 4.0)
        #expect(recipe.ingredientGroups[0].ingredients.count == 3)
        #expect(recipe.instructions != nil)
    }

    // MARK: - Diagnostics

    @Test("Parse with diagnostics returns success")
    func parseWithDiagnosticsSuccess() {
        let markdown = "# Test Recipe\n\n---\n\n- item"

        let result = parser.parseWithDiagnostics(markdown)
        switch result {
        case .success(let recipe):
            #expect(recipe.title == "Test Recipe")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Parse with diagnostics returns failure")
    func parseWithDiagnosticsFailure() {
        let markdown = "No title here"

        let result = parser.parseWithDiagnostics(markdown)
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            #expect(error == .missingTitle)
        }
    }
}
