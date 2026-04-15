import 'package:flutter/material.dart';

import '../../domain/entities/task_item.dart';
import '../task_card_ui_status.dart';

class TaskCardTile extends StatelessWidget {
  const TaskCardTile({
    super.key,
    required this.task,
    required this.status,
    this.onTap,
  });

  final TaskItem task;
  final TaskCardUiStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final borderColor = switch (status) {
      TaskCardUiStatus.error => scheme.error,
      TaskCardUiStatus.saving => scheme.primary.withValues(alpha: 0.5),
      TaskCardUiStatus.dragging => scheme.outline,
      TaskCardUiStatus.idle => scheme.outlineVariant.withValues(alpha: 0.35),
    };

    final elevation = switch (status) {
      TaskCardUiStatus.dragging => 6.0,
      _ => 0.0,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        elevation: elevation,
        shadowColor: scheme.shadow.withValues(alpha: 0.25),
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: status == TaskCardUiStatus.error ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (status == TaskCardUiStatus.error)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.error_outline, size: 18, color: scheme.error),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '#${task.indicatorToMoId}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                if (status == TaskCardUiStatus.saving) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
