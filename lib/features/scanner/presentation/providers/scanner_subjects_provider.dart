import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ScannerSubjectsState {
  final List<dynamic> subjects;
  final bool loading;
  final String? educationLevel;

  const ScannerSubjectsState({
    this.subjects = const [],
    this.loading = false,
    this.educationLevel,
  });
}

class ScannerSubjectsNotifier extends Notifier<ScannerSubjectsState> {
  @override
  ScannerSubjectsState build() => const ScannerSubjectsState();

  Future<void> load({required String level}) async {
    if (state.educationLevel == level && state.subjects.isNotEmpty) return;
    state = ScannerSubjectsState(loading: true, educationLevel: level);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.query(
        QueryOptions(
          document: gql(kSubjects),
          variables: {'educationLevel': level},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );
      if (result.hasException) {
        state = ScannerSubjectsState(educationLevel: level, loading: false);
        return;
      }
      state = ScannerSubjectsState(
        subjects: (result.data?['subjects'] as List?) ?? [],
        educationLevel: level,
        loading: false,
      );
    } catch (_) {
      state = ScannerSubjectsState(educationLevel: level, loading: false);
    }
  }
}

final scannerSubjectsProvider =
    NotifierProvider<ScannerSubjectsNotifier, ScannerSubjectsState>(
  ScannerSubjectsNotifier.new,
);
