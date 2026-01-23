import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
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
  final bool isLoading;
  final String? errorMessage;

  CustomerEmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerEmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerEmployeeState(
      employees: employees ?? this.employees,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
  Future<void> fetchEmployees() async {
    print('\n========== FETCH EMPLOYEES START ==========');

    if (state.employees.isNotEmpty) {
      print(
        '⏭️ [PROVIDER] Employees already loaded: ${state.employees.length}',
      );
      return;
    }

    print('🔄 [PROVIDER] Starting to fetch employees...');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getEmployees();
      print('📥 [PROVIDER] Repository response received');
      print('   - Success: ${response.success}');
      print('   - Data count: ${response.data?.length ?? 0}');
      print('   - Message: ${response.message ?? "none"}');

      if (response.success && response.data != null) {
        print(
          '✅ [PROVIDER] Setting ${response.data!.length} employees to state',
        );
        state = state.copyWith(
          isLoading: false,
          employees: response.data!,
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
  Future<void> refreshEmployees() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _repository.getEmployees();

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          employees: response.data!,
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
