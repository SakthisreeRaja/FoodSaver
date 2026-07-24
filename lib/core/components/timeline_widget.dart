import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineTile> children;

  const TimelineWidget({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children,
    );
  }
}

class TimelineTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;

  const TimelineTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
                ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
