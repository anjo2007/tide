import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tide/providers/task_provider.dart';
import 'package:tide/theme/app_theme.dart';

class StatSummary extends StatelessWidget {
  const StatSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 600;

    final now = DateTime.now();
    final todayTasksCount = taskProvider.tasks.where((t) {
      final dueDate = t.dueDate;
      return dueDate.year == now.year && dueDate.month == now.month && dueDate.day == now.day && !t.isCompleted;
    }).length;

    return GridView.count(
      crossAxisCount: isCompact ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isCompact ? 1.35 : 1.5,
      children: [
        // 1. Completion Progress Card
        _buildStatCard(
          context: context,
          title: 'Progress',
          widget: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(taskProvider.completionRate * 100).toInt()}%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              SizedBox(
                height: 42,
                width: 42,
                child: CircularProgressIndicator(
                  value: taskProvider.completionRate,
                  backgroundColor: AppTheme.creamBg,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successSage),
                  strokeWidth: 5,
                ),
              ),
            ],
          ),
          bgColor: Colors.white,
        ),

        // 2. Pending Tasks Card
        _buildStatCard(
          context: context,
          title: 'Pending',
          widget: Text(
            '${taskProvider.pendingCount}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
          ),
          bgColor: Colors.white,
          accentColor: AppTheme.infoBlue,
        ),

        // 3. High Priority Card
        _buildStatCard(
          context: context,
          title: 'Urgent',
          widget: Text(
            '${taskProvider.highPriorityCount}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: const Color(0xFFC05A5A),
                  fontWeight: FontWeight.w800,
                ),
          ),
          bgColor: AppTheme.dangerRose.withOpacity(0.08),
          accentColor: AppTheme.dangerRose,
        ),

        // 4. Today's Agenda Card
        _buildStatCard(
          context: context,
          title: 'Today',
          widget: Text(
            '$todayTasksCount',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.goldAccent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          bgColor: AppTheme.goldLight.withOpacity(0.3),
          accentColor: AppTheme.goldAccent,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required Widget widget,
    required Color bgColor,
    Color accentColor = AppTheme.goldAccent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(
          color: const Color(0xFFECE7DF),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: widget,
            ),
          ),
        ],
      ),
    );
  }
}
