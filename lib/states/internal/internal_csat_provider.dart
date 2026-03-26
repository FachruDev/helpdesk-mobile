import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:helpdesk_mobile/data/repository/internal/internal_ticket_repository.dart';
import 'package:helpdesk_mobile/states/internal/internal_ticket_provider.dart';

class InternalCsatState {
  final List<TicketModel> tickets;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSendingReminderAll;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final int lastPage;
  final String csatStatus;
  final String? ticketStatus;
  final String? search;
  final String? startDate;
  final String? endDate;

  InternalCsatState({
    this.tickets = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSendingReminderAll = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
    this.lastPage = 1,
    this.csatStatus = 'pending',
    this.ticketStatus,
    this.search,
    this.startDate,
    this.endDate,
  });

  InternalCsatState copyWith({
    List<TicketModel>? tickets,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSendingReminderAll,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    int? lastPage,
    String? csatStatus,
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
  }) {
    return InternalCsatState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSendingReminderAll: isSendingReminderAll ?? this.isSendingReminderAll,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      csatStatus: csatStatus ?? this.csatStatus,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      search: search ?? this.search,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class InternalCsatNotifier extends Notifier<InternalCsatState> {
  InternalTicketRepository get _repository =>
      ref.read(internalTicketRepositoryProvider);

  @override
  InternalCsatState build() {
    return InternalCsatState();
  }

  Future<void> fetchTickets({
    String? csatStatus,
    String? ticketStatus,
    String? search,
    String? startDate,
    String? endDate,
    bool refresh = false,
  }) async {
    final nextCsatStatus = csatStatus ?? state.csatStatus;
    final nextTicketStatus = ticketStatus ?? state.ticketStatus;
    final nextSearch = search ?? state.search;
    final nextStartDate = startDate ?? state.startDate;
    final nextEndDate = endDate ?? state.endDate;

    if (refresh) {
      state = InternalCsatState(
        isLoading: true,
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
      );
    } else {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
      );
    }

    try {
      final response = await _repository.getCsatTickets(
        csatStatus: nextCsatStatus,
        ticketStatus: nextTicketStatus,
        search: nextSearch,
        startDate: nextStartDate,
        endDate: nextEndDate,
        page: 1,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final lastPage = response.meta?.lastPage ?? 1;
        state = state.copyWith(
          isLoading: false,
          tickets: response.data!,
          currentPage: 1,
          lastPage: lastPage,
          hasMore: 1 < lastPage,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch CSAT tickets',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMoreTickets() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repository.getCsatTickets(
        csatStatus: state.csatStatus,
        ticketStatus: state.ticketStatus,
        search: state.search,
        startDate: state.startDate,
        endDate: state.endDate,
        page: nextPage,
        perPage: 20,
      );

      if (response.success && response.data != null) {
        final lastPage = response.meta?.lastPage ?? state.lastPage;
        state = state.copyWith(
          isLoadingMore: false,
          tickets: [...state.tickets, ...response.data!],
          currentPage: nextPage,
          lastPage: lastPage,
          hasMore: nextPage < lastPage,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> sendReminder(int ticketId) async {
    final response = await _repository.sendCsatReminder(ticketId);
    if (!response.success) {
      state = state.copyWith(errorMessage: response.message);
      return false;
    }
    return true;
  }

  Future<bool> sendReminderAll() async {
    state = state.copyWith(isSendingReminderAll: true, errorMessage: null);

    final response = await _repository.sendCsatReminderAll(
      ticketStatus: state.ticketStatus,
      search: state.search,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    state = state.copyWith(isSendingReminderAll: false);

    if (!response.success) {
      state = state.copyWith(errorMessage: response.message);
      return false;
    }

    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final internalCsatProvider =
    NotifierProvider<InternalCsatNotifier, InternalCsatState>(() {
  return InternalCsatNotifier();
});
