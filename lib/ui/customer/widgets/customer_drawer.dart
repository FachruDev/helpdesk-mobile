import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';

class CustomerDrawer extends StatelessWidget {
  final dynamic user;
  final VoidCallback onDashboardTap;
  final VoidCallback onCreateTicketTap;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const CustomerDrawer({
    super.key,
    required this.user,
    required this.onDashboardTap,
    required this.onCreateTicketTap,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    final userName = user?.name ?? 'User';
    final userImage = user?.imageUrl;

    return Drawer(
      child: Container(
        color: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    backgroundImage: userImage != null
                        ? CachedNetworkImageProvider(userImage)
                        : null,
                    child: userImage == null
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: AppColors.primary,
                          )
                        : null,
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
              onTap: onDashboardTap,
            ),
            _buildDrawerItem(
              icon: Icons.add_box,
              title: 'Create Ticket',
              onTap: onCreateTicketTap,
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: onProfileTap,
            ),
            const Divider(color: AppColors.white, height: 1),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: onLogoutTap,
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
        style: const TextStyle(color: AppColors.white),
      ),
      onTap: onTap,
    );
  }
}
