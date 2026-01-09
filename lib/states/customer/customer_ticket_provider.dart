import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/customer/customer_ticket_repository.dart';

// Repository Provider
final customerTicketRepositoryProvider = Provider<CustomerTicketRepository>((ref) {
  return CustomerTicketRepository();
});

// Ticket List State
class CustomerTicketState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  CustomerTicketState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
  });

  CustomerTicketState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return CustomerTicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Ticket Notifier
class CustomerTicketNotifier extends Notifier<CustomerTicketState> {
  CustomerTicketRepository get _repository => ref.read(customerTicketRepositoryProvider);

  @override
  CustomerTicketState build() {
    return CustomerTicketState();
  }

  // Fetch tickets with filters
  Future<void> fetchTickets({
    String? status,
    String? startDate,
    String? endDate,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = CustomerTicketState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final response = await _repository.getTickets(
        status: status,
        startDate: startDate,
        endDate: endDate,
        search: search,
        page: 1,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        state = state.copyWith(
          isLoading: false,
          tickets: response.data!,
          currentPage: 1,
          hasMore: response.data!.length >= 20,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch tickets',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Load more tickets (pagination)
  Future<void> loadMoreTickets({
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getTickets(
        status: status,
        startDate: startDate,
        endDate: endDate,
        search: search,
        page: nextPage,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final newTickets = [...state.tickets, ...response.data!];
        state = state.copyWith(
          isLoadingMore: false,
          tickets: newTickets,
          currentPage: nextPage,
          hasMore: response.data!.length >= 20,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  // Create ticket
  Future<bool> createTicket({
    required String subject,
    required int categoryId,
    required String message,
    required String requestToUserId,
    String? requestToOther,
    String? project,
    int? subCategory,
    String? envatoSupport,
    List<File>? files,
  }) async {
    try {
      final response = await _repository.createTicket(
        subject: subject,
        categoryId: categoryId,
        message: message,
        requestToUserId: requestToUserId,
        requestToOther: requestToOther,
        project: project,
        subCategory: subCategory,
        envatoSupport: envatoSupport,
        files: files,
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final customerTicketProvider = NotifierProvider<CustomerTicketNotifier, CustomerTicketState>(() {
  return CustomerTicketNotifier();
});

// Ticket Detail Provider (separate for each ticket)
final customerTicketDetailProvider = FutureProvider.family<TicketModel?, String>((ref, ticketId) async {
  final repository = ref.watch(customerTicketRepositoryProvider);
  final response = await repository.getTicketDetail(ticketId);
  
  if (response.success && response.data != null) {
    return response.data;
  }
  return null;
});

// Reply Ticket Provider
final customerReplyTicketProvider = Provider<CustomerTicketRepository>((ref) {
  return ref.watch(customerTicketRepositoryProvider);
});
