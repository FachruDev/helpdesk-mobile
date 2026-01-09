import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/category_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';

// Repository Provider
final customerCategoryRepositoryProvider = Provider<CustomerTicketRepository>((ref) {
  return CustomerTicketRepository();
});

// Category State
class CustomerCategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? errorMessage;

  CustomerCategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerCategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerCategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// Category Notifier
class CustomerCategoryNotifier extends Notifier<CustomerCategoryState> {
  CustomerTicketRepository get _repository => ref.read(customerCategoryRepositoryProvider);

  @override
  CustomerCategoryState build() {
    return CustomerCategoryState();
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    if (state.categories.isNotEmpty) {
      // Already loaded, skip
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getCategories();

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          categories: response.data!,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch categories',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Refresh categories
  Future<void> refreshCategories() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getCategories();

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          categories: response.data!,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch categories',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(int categoryId) {
    try {
      return state.categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final customerCategoryProvider = NotifierProvider<CustomerCategoryNotifier, CustomerCategoryState>(() {
  return CustomerCategoryNotifier();
});
