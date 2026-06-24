import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/models/category_model.dart';
import 'package:tide/providers/auth_provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';

class SidebarMenu extends StatelessWidget {
  final bool isDrawer;
  const SidebarMenu({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final user = auth.user;

    final categories = [
      CategoryModel(id: 'all', name: 'All Tasks', iconName: 'all', colorValue: 0xFFC5A059),
      ...CategoryModel.defaultCategories
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.creamBg,
        border: isDrawer
            ? null
            : const Border(
                right: BorderSide(color: Color(0xFFECE7DF), width: 1.5),
              ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.goldLight,
                    backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user?.photoUrl == null || user!.photoUrl!.isEmpty
                        ? Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName.substring(0, 1).toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: AppTheme.goldAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'User',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textDark,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'offline@Tide.com',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFECE7DF), height: 1),
            const SizedBox(height: 16),

            // Navigation/Category Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'CATEGORIES',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.5,
                    ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == 'all'
                      ? taskProvider.selectedCategoryId == null
                      : taskProvider.selectedCategoryId == cat.id;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.goldLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (cat.id == 'all') {
                          taskProvider.setSelectedCategoryId(null);
                        } else {
                          taskProvider.setSelectedCategoryId(cat.id);
                        }
                        if (isDrawer) {
                          Navigator.pop(context);
                        }
                      },
                      dense: true,
                      horizontalTitleGap: 8,
                      leading: Icon(
                        cat.id == 'all' ? Icons.grid_view_rounded : cat.iconData,
                        color: isSelected ? AppTheme.goldAccent : AppTheme.textMuted,
                        size: 20,
                      ),
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? AppTheme.textDark : AppTheme.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Logout Footer
            const Divider(color: Color(0xFFECE7DF), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  auth.signOut();
                  taskProvider.unbindTasks();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFE5A9A9), width: 1.2),
                  foregroundColor: const Color(0xFFC05A5A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
