import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/states/customer/customer_auth_provider.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch user profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(customerAuthProvider).user == null) {
        ref.read(customerAuthProvider.notifier).fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(customerAuthProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Name',
                            value: user.name,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: user.email,
                          ),
                          if (user.phone != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: user.phone!,
                            ),
                          ],
                          if (user.company != null) ...[
                            const Divider(),
                            _buildInfoRow(
                              icon: Icons.business,
                              label: 'Company',
                              value: user.company!,
                            ),
                          ],
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.badge,
                            label: 'Role',
                            value: user.role,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
