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
        color: AppColors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.white,
                        backgroundImage: userImage != null
                            ? CachedNetworkImageProvider(userImage)
                            : null,
                        child: userImage == null
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.primary,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User name
                    Text(
                      userName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Customer',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      onTap: onDashboardTap,
                    ),
                    const SizedBox(height: 4),
                    _buildDrawerItem(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Create Ticket',
                      onTap: onCreateTicketTap,
                    ),
                    const SizedBox(height: 4),
                    _buildDrawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      onTap: onProfileTap,
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: AppColors.textHint.withOpacity(0.2),
                        thickness: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: onLogoutTap,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
              
              // Footer version info (optional)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Helpdesk v1.0.0',
                  style: TextStyle(
                    color: AppColors.textHint.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? AppColors.error : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
