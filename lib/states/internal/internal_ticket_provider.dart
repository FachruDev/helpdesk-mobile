import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_ticket_repository.dart';

// Repository Provider
final internalTicketRepositoryProvider = Provider<InternalTicketRepository>((
  ref,
) {
  return InternalTicketRepository();
});

// Ticket List State
class InternalTicketState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  InternalTicketState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
  });

  InternalTicketState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return InternalTicketState(
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
class InternalTicketNotifier extends Notifier<InternalTicketState> {
  InternalTicketRepository get _repository =>
      ref.read(internalTicketRepositoryProvider);

  @override
  InternalTicketState build() {
    return InternalTicketState();
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
      state = InternalTicketState(isLoading: true);
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
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
    required String email,
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
        email: email,
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
final internalTicketProvider =
    NotifierProvider<InternalTicketNotifier, InternalTicketState>(() {
      return InternalTicketNotifier();
    });

// Ticket Detail Provider (separate for each ticket)
final internalTicketDetailProvider =
    FutureProvider.family<TicketModel?, String>((ref, ticketId) async {
      final repository = ref.watch(internalTicketRepositoryProvider);
      final response = await repository.getTicketDetail(ticketId);

      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    });

// Reply Ticket Provider
final internalReplyTicketProvider = Provider<InternalTicketRepository>((ref) {
  return ref.watch(internalTicketRepositoryProvider);
});
