import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';
import 'package:helpdesk_mobile/states/customer/customer_ticket_provider.dart';
import 'package:helpdesk_mobile/ui/customer/create_ticket_screen.dart';
import 'package:helpdesk_mobile/ui/customer/filter_screen.dart';
import 'package:helpdesk_mobile/ui/customer/profile_screen.dart';
import 'package:helpdesk_mobile/ui/customer/ticket_detail_screen.dart';
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
      drawer: _buildDrawer(authState.user?.name ?? 'User'),
      body: RefreshIndicator(
        onRefresh: _refreshTickets,
        child: ticketState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ticketState.tickets.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: ticketState.tickets.length + 
                        (ticketState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
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
            'Create a new ticket to get started',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String userName) {
    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    child: Icon(
                      Icons.person,
                      size: 35,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Customer',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.add_box,
              title: 'Create Ticket',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerCreateTicketScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerProfileScreen(),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.white, height: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,  
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }
}
