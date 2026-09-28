import '../../core/database/database_helper.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/alternative_model.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper;

  ProductRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<ProductModel?> getProductByBarcode(String barcode) {
    return _dbHelper.getProductByBarcode(barcode);
  }

  Future<List<AlternativeModel>> getAlternatives(String productId) {
    return _dbHelper.getAlternatives(productId);
  }

  Future<List<ProductModel>> searchProducts(String query) {
    return _dbHelper.searchProducts(query);
  }

  Future<List<CategoryModel>> getCategories() {
    return _dbHelper.getCategories();
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _dbHelper.getProductsByCategory(categoryId);
  }

  Future<List<ProductModel>> getFeaturedProducts() {
    return _dbHelper.getFeaturedProducts();
  }
}
