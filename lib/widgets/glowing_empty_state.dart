import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GlowingEmptyState extends StatelessWidget {
  const GlowingEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: primaryColor.withValues(alpha: 0.2),
            highlightColor: primaryColor.withValues(alpha: 0.8),
            period: const Duration(milliseconds: 2500),
            child: const Icon(
              Icons.auto_awesome,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No notes yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Write your beautiful thoughts here...",
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
