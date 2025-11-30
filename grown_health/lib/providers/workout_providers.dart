import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/categories_service.dart';

final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  return CategoriesService();
});

final categoriesProvider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch(categoriesServiceProvider);
  return service.fetchCategories();
});
