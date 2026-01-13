import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/states/internal/internal_auth_provider.dart';

class InternalProfileScreen extends ConsumerStatefulWidget {
  const InternalProfileScreen({super.key});

  @override
  ConsumerState<InternalProfileScreen> createState() => _InternalProfileScreenState();
}

class _InternalProfileScreenState extends ConsumerState<InternalProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch user profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(internalAuthProvider).user == null) {
        ref.read(internalAuthProvider.notifier).fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(internalAuthProvider);
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
                    backgroundImage: user.imageUrl != null
                        ? CachedNetworkImageProvider(user.imageUrl!)
                        : null,
                    child: user.imageUrl == null
                        ? const Icon(
                            Icons.admin_panel_settings,
                            size: 60,
                            color: AppColors.white,
                          )
                        : null,
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
                            value: user.displayRole,
                          ),
                          if (user.roles != null && user.roles!.length > 1) ...[
                            const Divider(),
                            _buildRolesRow(
                              icon: Icons.admin_panel_settings,
                              label: 'All Roles',
                              roles: user.roles!,
                            ),
                          ],
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

  Widget _buildRolesRow({
    required IconData icon,
    required String label,
    required List<String> roles,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles.map((role) {
                    final displayRole = role.substring(0, 1).toUpperCase() + role.substring(1);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        displayRole,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
