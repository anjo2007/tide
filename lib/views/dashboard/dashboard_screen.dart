import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/providers/auth_provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';
import 'package:tide/views/dashboard/widgets/sidebar_menu.dart';
import 'package:tide/views/dashboard/widgets/stat_summary.dart';
import 'package:tide/views/dashboard/widgets/task_list.dart';
import 'package:tide/views/task/task_editor_screen.dart';
import 'package:tide/views/dashboard/widgets/ai_assistant_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  bool _showAiAssistant = false;

  void _toggleAiAssistant() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;
    if (isDesktop) {
      setState(() {
        _showAiAssistant = !_showAiAssistant;
      });
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: AIAssistantPanel(
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<TaskProvider>(context, listen: false).bindUserTasks(auth.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    final mainContent = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspace',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: isDesktop ? 32 : 26,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your daily agenda',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (!isDesktop)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 28),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics Dashboard Cards
          const StatSummary(),
          const SizedBox(height: 32),

          // Filters and Search Bar Section
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => taskProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Sort Menu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECE7DF), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: taskProvider.sortBy,
                    icon: const Icon(Icons.sort_rounded, color: AppTheme.goldAccent),
                    onChanged: (String? val) {
                      if (val != null) taskProvider.setSortBy(val);
                    },
                    items: const [
                      DropdownMenuItem(value: 'dueDate', child: Text('Due Date')),
                      DropdownMenuItem(value: 'priority', child: Text('Priority')),
                      DropdownMenuItem(value: 'createdAt', child: Text('Date Created')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Status & Priority Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Pills
                _buildFilterTab(context, 'All', taskProvider.statusFilter == 'All', () {
                  taskProvider.setStatusFilter('All');
                }),
                _buildFilterTab(context, 'Pending', taskProvider.statusFilter == 'Pending', () {
                  taskProvider.setStatusFilter('Pending');
                }),
                _buildFilterTab(context, 'Completed', taskProvider.statusFilter == 'Completed', () {
                  taskProvider.setStatusFilter('Completed');
                }),
                
                const SizedBox(width: 12),
                Container(width: 1.5, height: 24, color: const Color(0xFFECE7DF)),
                const SizedBox(width: 12),

                // Priority Pills
                _buildFilterTab(context, 'All Prios', taskProvider.priorityFilter == 'All', () {
                  taskProvider.setPriorityFilter('All');
                }),
                _buildFilterTab(context, '🔴 High', taskProvider.priorityFilter == 'High', () {
                  taskProvider.setPriorityFilter('High');
                }),
                _buildFilterTab(context, '🟡 Medium', taskProvider.priorityFilter == 'Medium', () {
                  taskProvider.setPriorityFilter('Medium');
                }),
                _buildFilterTab(context, '🔵 Low', taskProvider.priorityFilter == 'Low', () {
                  taskProvider.setPriorityFilter('Low');
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tasks List
          const TaskList(),
        ],
      ),
    );

    return Scaffold(
      endDrawer: !isDesktop ? const Drawer(child: SidebarMenu(isDrawer: true)) : null,
      body: Row(
        children: [
          if (isDesktop) const SidebarMenu(),
          Expanded(
            child: Scaffold(
              body: SafeArea(child: mainContent),
              floatingActionButton: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'ai_chat_fab',
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: Colors.white,
                    tooltip: 'Ask Tide AI',
                    onPressed: _toggleAiAssistant,
                    child: Icon(
                      isDesktop && _showAiAssistant
                          ? Icons.close_rounded
                          : Icons.forum_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'add_task_fab',
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      if (auth.user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskEditorScreen(userId: auth.user!.uid),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          if (isDesktop && _showAiAssistant)
            AIAssistantPanel(
              onClose: () => setState(() => _showAiAssistant = false),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFECE7DF),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
