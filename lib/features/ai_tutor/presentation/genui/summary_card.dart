import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final summaryCardSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['SummaryCard']),
    'title': S.string(description: 'The title of the summary'),
    'points': S.list(
      description: 'Key takeaways or bullet points',
      items: S.object(
        properties: {
          'heading': S.string(description: 'Short heading for the point'),
          'details': S.string(description: 'Detailed explanation of the point'),
        },
        required: ['heading', 'details'],
      ),
    ),
  },
  required: ['component', 'title', 'points'],
);

class _SummaryPoint {
  final String heading;
  final String details;

  _SummaryPoint({required this.heading, required this.details});

  factory _SummaryPoint.fromJson(Map<String, Object?> json) {
    return _SummaryPoint(
      heading: json['heading'] as String,
      details: json['details'] as String,
    );
  }
}

class _SummaryCardData {
  final String title;
  final List<_SummaryPoint> points;

  _SummaryCardData({required this.title, required this.points});

  factory _SummaryCardData.fromJson(Map<String, Object?> json) {
    try {
      return _SummaryCardData(
        title: json['title'] as String,
        points: (json['points'] as List<Object?>)
            .map((e) => _SummaryPoint.fromJson(e as Map<String, Object?>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Invalid JSON for _SummaryCardData: $e');
    }
  }
}

class _SummaryCardWidget extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCardWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.secondaryContainer, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point.heading,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              point.details,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

final summaryCardItem = CatalogItem(
  name: 'SummaryCard',
  dataSchema: summaryCardSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _SummaryCardData.fromJson(json);

    return _SummaryCardWidget(data: data);
  },
);
