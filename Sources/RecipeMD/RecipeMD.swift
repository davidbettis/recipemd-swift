// RecipeMD - A Swift library for parsing and generating RecipeMD-formatted recipes.
//
// RecipeMD is a Markdown-based format for writing recipes. This library provides
// types and utilities for working with RecipeMD documents.
//
// For more information about the RecipeMD format, see https://recipemd.org

/// RecipeMD library version.
public let version = "0.0.1"

// MARK: - Quick Start
//
// ## Parsing a Recipe
//
// ```swift
// import RecipeMD
//
// let markdown = """
// # Guacamole
//
// A fresh Mexican dip.
//
// *vegan, Mexican*
// **4 Servings**
//
// ---
//
// - *2* ripe avocados
// - *½ teaspoon* salt
// - *1 tablespoon* lime juice
//
// ---
//
// Mash avocados in a bowl. Add salt and lime juice, mix well.
// """
//
// let parser = RecipeMDParser()
// let recipe = try parser.parse(markdown)
//
// print(recipe.title)  // "Guacamole"
// print(recipe.tags)   // ["vegan", "Mexican"]
// ```
//
// ## Creating a Recipe
//
// ```swift
// let recipe = Recipe(
//     title: "Guacamole",
//     description: "A fresh Mexican dip.",
//     tags: ["vegan", "Mexican"],
//     yields: [.servings(4)],
//     ingredientGroups: [
//         IngredientGroup(ingredients: [
//             Ingredient(name: "avocados", amount: 2),
//             Ingredient(name: "salt", amount: .fraction(1, 2), unit: "teaspoon")
//         ])
//     ],
//     instructions: "Mash and mix."
// )
// ```
//
// ## Generating Markdown
//
// ```swift
// let generator = RecipeMDGenerator()
// let markdown = generator.generate(recipe)
//
// // With options
// let options = GeneratorOptions(useUnicodeFractions: true)
// let prettyMarkdown = generator.generate(recipe, options: options)
// ```
