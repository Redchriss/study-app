import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:studyapp/core/graphql/client.dart';
import 'package:studyapp/core/theme/app_theme.dart';
import 'package:studyapp/router.dart';

Widget createTestApp() {
  final client = buildGraphQLClient();
  return ProviderScope(
    child: GraphQLProvider(
      client: ValueNotifier(client),
      child: MaterialApp.router(
        routerConfig: null,
        theme: AppTheme.light(),
      ),
    ),
  );
}

void main() {
  testWidgets('Providers initialize without error', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp());
    expect(true, isTrue);
  });
}
