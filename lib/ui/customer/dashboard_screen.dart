import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';
import 'package:helpdesk_mobile/ui/customer/create_ticket_screen.dart';
import 'package:helpdesk_mobile/ui/customer/filter_screen.dart';
import 'package:helpdesk_mobile/ui/customer/profile_screen.dart';
import 'package:helpdesk_mobile/ui/customer/ticket_detail_screen.dart';
import 'package:helpdesk_mobile/ui/customer/widgets/customer_drawer.dart';
import 'package:helpdesk_mobile/ui/customer/widgets/ticket_statistics_widget.dart';
import 'package:helpdesk_mobile/ui/shared/widgets/ticket_card.dart';
import 'package:helpdesk_mobile/ui/customer/login_screen.dart';

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  ConsumerState<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends ConsumerState<CustomerDashboardScreen> {
  String? _selectedStatus;
  String? _startDate;
  String? _endDate;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    // Load tickets on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerTicketProvider.notifier).fetchTickets(refresh: true);
    });
  }

  Future<void> _refreshTickets() async {
    await ref.read(customerTicketProvider.notifier).fetchTickets(
          status: _selectedStatus,
          startDate: _startDate,
          endDate: _endDate,
          search: _searchQuery,
          refresh: true,
        );
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
      _startDate = null;
      _endDate = null;
      _searchQuery = null;
    });

    ref.read(customerTicketProvider.notifier).fetchTickets(
          status: status,
          refresh: true,
        );
  }

  void _openFilterScreen() async {
    final result = await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerFilterScreen(
          initialStatus: _selectedStatus,
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          initialSearch: _searchQuery,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStatus = result['status'];
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _searchQuery = result['search'];
      });

      ref.read(customerTicketProvider.notifier).fetchTickets(
            status: _selectedStatus,
            startDate: _startDate,
            endDate: _endDate,
            search: _searchQuery,
            refresh: true,
          );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(customerAuthProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(customerTicketProvider);
    final authState = ref.watch(customerAuthProvider);

    // Calculate statistics from tickets (all tickets, not filtered)
    final allTickets = ticketState.tickets;
    final totalTickets = allTickets.length;
    final inProgressTickets = allTickets.where((t) => t.status.value.toLowerCase() == 'inprogress').length;
    final closedTickets = allTickets.where((t) => t.status.value.toLowerCase() == 'closed').length;
    final cancelledTickets = allTickets.where((t) => t.status.value.toLowerCase() == 'cancelled').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterScreen,
            tooltip: 'Filter Tickets',
          ),
        ],
      ),
      drawer: CustomerDrawer(
        user: authState.user,
        onDashboardTap: () => Navigator.pop(context),
        onCreateTicketTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerCreateTicketScreen(),
            ),
          );
        },
        onProfileTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerProfileScreen(),
            ),
          );
        },
        onLogoutTap: () {
          Navigator.pop(context);
          _handleLogout();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTickets,
        child: ticketState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Statistics Section
                  SliverToBoxAdapter(
                    child: TicketStatisticsWidget(
                      totalTickets: totalTickets,
                      inProgressTickets: inProgressTickets,
                      closedTickets: closedTickets,
                      cancelledTickets: cancelledTickets,
                      onStatusTap: _filterByStatus,
                    ),
                  ),
                  
                  // Active Filter Indicator
                  if (_selectedStatus != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Filtered by: $_selectedStatus',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _filterByStatus(null),
                              child: Icon(Icons.close, size: 18, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Tickets List
                  ticketState.tickets.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 80,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == ticketState.tickets.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final ticket = ticketState.tickets[index];
                                return TicketCard(
                                  ticket: ticket,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerTicketDetailScreen(
                                          ticketId: ticket.ticketId,
                                        ),
                                      ),
                                    );
                                    // Refresh tickets when returning from detail
                                    _refreshTickets();
                                  },
                                );
                              },
                              childCount: ticketState.tickets.length + 
                                  (ticketState.isLoadingMore ? 1 : 0),
                            ),
                          ),
                        ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerCreateTicketScreen(),
            ),
          );
          // Refresh tickets if ticket was created successfully
          if (result == true) {
            await _refreshTickets();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No tickets found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null
                ? 'No tickets with status: $_selectedStatus'
                : 'Create a new ticket to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

