import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/employee_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';

// Repository Provider
final customerEmployeeRepositoryProvider = Provider<CustomerTicketRepository>((ref) {
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
  CustomerTicketRepository get _repository => ref.read(customerEmployeeRepositoryProvider);

  @override
  CustomerEmployeeState build() {
    return CustomerEmployeeState();
  }

  // Fetch employees
  Future<void> fetchEmployees() async {
    if (state.employees.isNotEmpty) {
      // Already loaded, skip
      return;
    }

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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
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
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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
final customerEmployeeProvider = NotifierProvider<CustomerEmployeeNotifier, CustomerEmployeeState>(() {
  return CustomerEmployeeNotifier();
});
