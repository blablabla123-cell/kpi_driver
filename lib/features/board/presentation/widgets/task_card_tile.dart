import 'package:flutter/material.dart';

import '../../domain/entities/task_item.dart';
import '../card_density.dart';
import '../task_card_ui_status.dart';

class TaskCardTile extends StatelessWidget {
  const TaskCardTile({
    super.key,
    required this.task,
    required this.status,
    this.density = CardDensity.comfortable,
    this.onTap,
  });

  final TaskItem task;
  final TaskCardUiStatus status;
  final CardDensity density;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = density == CardDensity.compact;
    final padH = compact ? 10.0 : 14.0;
    final padV = compact ? 8.0 : 12.0;
    final titleStyle = compact
        ? textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          )
        : textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.25,
          );
    final subtitleStyle = compact
        ? textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.1,
          )
        : textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.2,
          );
    final gapAfterTitle = compact ? 4.0 : 6.0;
    final gapBeforeProgress = compact ? 6.0 : 10.0;

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
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          side: BorderSide(color: borderColor, width: status == TaskCardUiStatus.error ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
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
                        style: titleStyle,
                        maxLines: compact ? 3 : 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (status == TaskCardUiStatus.error)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.error_outline,
                          size: compact ? 16 : 18,
                          color: scheme.error,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: gapAfterTitle),
                Text(
                  '#${task.indicatorToMoId}',
                  style: subtitleStyle,
                ),
                if (status == TaskCardUiStatus.saving) ...[
                  SizedBox(height: gapBeforeProgress),
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
