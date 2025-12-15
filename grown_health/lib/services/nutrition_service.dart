import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

/// Model class for Nutrition/Recipe items
class NutritionItem {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String type;
  final String image;
  final int calories;
  final int prepTime;
  final List<String> ingredients;
  final String instructions;
  final DateTime createdAt;

  NutritionItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.type,
    required this.image,
    required this.calories,
    required this.prepTime,
    required this.ingredients,
    required this.instructions,
    required this.createdAt,
  });

  factory NutritionItem.fromJson(Map<String, dynamic> json) {
    return NutritionItem(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'Recipe',
      image: json['image'] ?? '',
      calories: json['calories'] ?? 0,
      prepTime: json['prepTime'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: json['instructions'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Service for nutrition-related API calls
class NutritionService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Fetch the recipe of the day
  static Future<NutritionItem?> getRecipeOfTheDay() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition/recipe-of-the-day'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NutritionItem.fromJson(data);
      } else if (response.statusCode == 404) {
        // No recipes available
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching recipe of the day: $e');
      return null;
    }
  }

  /// Fetch all recipes with pagination
  static Future<List<NutritionItem>> getRecipes({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'type': 'Recipe',
        if (search != null && search.isNotEmpty) 'q': search,
      };

      final uri = Uri.parse(
        '$_baseUrl/nutrition',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipes = data['data'] as List<dynamic>;
        return recipes.map((json) => NutritionItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching recipes: $e');
      return [];
    }
  }

  /// Fetch a single recipe by ID
  static Future<NutritionItem?> getRecipeById(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/nutrition/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NutritionItem.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching recipe: $e');
      return null;
    }
  }
}
