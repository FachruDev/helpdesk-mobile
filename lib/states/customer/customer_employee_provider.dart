import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/models/employee_lookup_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';

// Repository Provider
final customerEmployeeRepositoryProvider = Provider<CustomerTicketRepository>((
  ref,
) {
  return CustomerTicketRepository();
});

// Employee State
class CustomerEmployeeState {
  final List<EmployeeModel> employees;
  final Map<String, String> subjectCategoryOptions;
  final bool isLoading;
  final String? errorMessage;
  final String subjectCategory;

  CustomerEmployeeState({
    this.employees = const [],
    this.subjectCategoryOptions =
        EmployeeLookupModel.defaultSubjectCategoryOptions,
    this.isLoading = false,
    this.errorMessage,
    this.subjectCategory = 'technical_support',
  });

  CustomerEmployeeState copyWith({
    List<EmployeeModel>? employees,
    Map<String, String>? subjectCategoryOptions,
    bool? isLoading,
    String? errorMessage,
    String? subjectCategory,
  }) {
    return CustomerEmployeeState(
      employees: employees ?? this.employees,
      subjectCategoryOptions:
          subjectCategoryOptions ?? this.subjectCategoryOptions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      subjectCategory: subjectCategory ?? this.subjectCategory,
    );
  }
}

// Employee Notifier
class CustomerEmployeeNotifier extends Notifier<CustomerEmployeeState> {
  CustomerTicketRepository get _repository =>
      ref.read(customerEmployeeRepositoryProvider);

  @override
  CustomerEmployeeState build() {
    return CustomerEmployeeState();
  }

  // Fetch employees
  Future<void> fetchEmployees({String subjectCategory = 'technical_support'}) async {
    print('\n========== FETCH EMPLOYEES START ==========');

    print('🔄 [PROVIDER] Starting to fetch employees...');
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      subjectCategory: subjectCategory,
    );

    try {
      final response = await _repository.getEmployeesLookup(
        subjectCategory: subjectCategory,
      );
      print('📥 [PROVIDER] Repository response received');
      print('   - Success: ${response.success}');
      print('   - Data count: ${response.data?.employees.length ?? 0}');
      print('   - Message: ${response.message ?? "none"}');

      if (response.success && response.data != null) {
        print(
          '✅ [PROVIDER] Setting ${response.data!.employees.length} employees to state',
        );
        state = state.copyWith(
          isLoading: false,
          employees: response.data!.employees,
          subjectCategoryOptions: response.data!.subjectCategoryOptions,
          errorMessage: null,
        );
        print('✅ [PROVIDER] State updated successfully');
        print('   - Current state employees: ${state.employees.length}');
        print(
          '   - First employee: ${state.employees.isNotEmpty ? state.employees.first.name : "none"}',
        );
      } else {
        print('❌ [PROVIDER] Failed to fetch employees: ${response.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch employees',
        );
      }
    } catch (e, stackTrace) {
      print('💥 [PROVIDER] Exception: $e');
      print('📚 [PROVIDER] Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }

    print('========== FETCH EMPLOYEES END ==========\n');
  }

  // Refresh employees
  Future<void> refreshEmployees({String? subjectCategory}) async {
    final nextCategory = subjectCategory ?? state.subjectCategory;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      subjectCategory: nextCategory,
    );

    try {
      final response = await _repository.getEmployeesLookup(
        subjectCategory: nextCategory,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          employees: response.data!.employees,
          subjectCategoryOptions: response.data!.subjectCategoryOptions,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch employees',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Get employee by ID
  EmployeeModel? getEmployeeById(int employeeId) {
    try {
      return state.employees.firstWhere((emp) => emp.id == employeeId);
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
final customerEmployeeProvider =
    NotifierProvider<CustomerEmployeeNotifier, CustomerEmployeeState>(() {
      return CustomerEmployeeNotifier();
    });
