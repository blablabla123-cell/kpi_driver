import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class BoardLoadingShimmer extends StatelessWidget {
  const BoardLoadingShimmer({super.key});

  static const double _columnWidth = 300;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(width: _gap),
          itemBuilder: (context, index) {
            return SizedBox(
              width: _columnWidth,
              height: constraints.maxHeight,
              child: Shimmer.fromColors(
                baseColor: scheme.surfaceContainerHighest,
                highlightColor: scheme.surfaceContainerHigh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, _) => Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
