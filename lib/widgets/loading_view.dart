import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  final double progress;

  const LoadingView({
    super.key,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            backgroundColor: Colors.grey[200],
            minHeight: 3,
          ),
          // Loading overlay (only show at start)
          if (progress < 0.3)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
