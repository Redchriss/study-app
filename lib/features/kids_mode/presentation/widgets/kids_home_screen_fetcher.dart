import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:genui/genui.dart' hide TextPart;
import 'package:genui/genui.dart' as genui;
import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_state_provider.dart';
import '../../../ai_tutor/presentation/screens/ai_tutor_stream_service.dart';

class KidsHomeScreenFetcher {
  final WidgetRef ref;
  late final AiTutorStreamService streamService;
  late final A2uiTransportAdapter transport;
  final Catalog catalog;
  final bool Function() mountedFn;
  final BuildContext Function() contextFn;

  KidsHomeScreenFetcher({
    required this.ref,
    required this.catalog,
    required this.mountedFn,
    required this.contextFn,
  });

  void attachServices({
    required A2uiTransportAdapter transport,
    required AiTutorStreamService streamService,
  }) {
    this.transport = transport;
    this.streamService = streamService;
  }

  BuildContext get context => contextFn();

  void _update(KidsHomeState Function(KidsHomeState) cb) {
    ref.read(kidsHomeStateProvider.notifier).apply(cb);
  }

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
  }

  Future<void> sendAndReceive(ChatMessage msg) async {
    final buffer = StringBuffer();
    for (final part in msg.parts) {
      if (part.isUiInteractionPart) {
        buffer.write(part.asUiInteractionPart!.interaction);
      } else if (part is genui.TextPart) {
        buffer.write(part.text);
      }
    }
    final text = buffer.toString();
    if (text.isEmpty) return;
    final auth = ref.read(kidAuthStateProvider);
    if (!auth.isAuthenticated || auth.token == null) return;
    final promptBuilder = PromptBuilder.chat(catalog: catalog);
    final clientInstructions = promptBuilder.systemPromptJoined();
    final httpClient = http.Client();
    try {
      await streamService.sendStream(
        text: text,
        sessionId: null,
        studyMode: 'kids_lesson',
        token: auth.token!,
        clientInstructions: clientInstructions,
        httpClient: httpClient,
        onToken: (t) {
          transport.addChunk(t);
        },
        onAddMessage: (msg) {
          _update((s) => s.copyWith(loading: false));
        },
        onSessionId: (id) {},
        onError: (msg) {
          _update((s) => s.copyWith(loading: false));
          if (mountedFn()) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        onScrollDown: () {},
      );
    } catch (_) {
      if (!mountedFn()) return;
      _update((s) => s.copyWith(loading: false));
    } finally {
      httpClient.close();
    }
  }

  Future<void> fetchSubjects() async {
    _update((s) => s.copyWith(subjectFetchStarted: true));
    final auth = ref.read(kidAuthStateProvider);
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {
        'standard': auth.standard,
        'educationTrack': auth.educationTrack
      },
    ));
    if (result.data != null) {
      final subjects = ((result.data!['primarySubjects'] as List?) ?? [])
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      _update((s) => s.copyWith(
          subjects: subjects,
          fetchedSubjects: true,
          subjectFetchStarted: false));
      await fetchDailySummary();
      await fetchRewardProfile();
    } else {
      _update(
          (s) => s.copyWith(fetchedSubjects: true, subjectFetchStarted: false));
    }
  }

  Future<void> fetchDailySummary() async {
    final auth = ref.read(kidAuthStateProvider);
    if (!auth.isAuthenticated) return;
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidDailySummary),
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (result.data == null) return;
    final s = result.data!['kidDailySummary'] as Map<String, dynamic>?;
    if (s != null) {
      _update((prev) {
        final dailySummary = Map<String, dynamic>.from(s);
        final stars =
            (dailySummary['totalStars'] as num?)?.toInt() ?? prev.stars;
        return prev.copyWith(dailySummary: dailySummary, stars: stars);
      });
    }
  }

  Future<void> fetchRewardProfile() async {
    final result = await _buildKidClient().query(
      QueryOptions(
          document: gql(kKidRewardProfile),
          fetchPolicy: FetchPolicy.networkOnly),
    );
    final profile = result.data?['kidRewardProfile'];
    if (profile is Map) {
      _update(
          (s) => s.copyWith(rewardProfile: Map<String, dynamic>.from(profile)));
    }
  }

  Future<void> fetchRoadmap(String subjectId, int standard) async {
    final c = _buildKidClient();
    final roadmapResult = await c.query(QueryOptions(
      document: gql(kKidSubjectRoadmap),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final reviewResult = await c.query(QueryOptions(
      document: gql(kKidReviewQueue),
      variables: const {'limit': 4},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final roadmap = roadmapResult.data?['kidSubjectRoadmap'];
    _update((s) {
      final roadmapSummary = roadmap is Map && roadmap['summary'] is Map
          ? Map<String, dynamic>.from(roadmap['summary'] as Map)
          : null;
      final topicRoadmap =
          ((roadmap is Map ? roadmap['topics'] : null) as List? ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      final reviewQueue =
          ((reviewResult.data?['kidReviewQueue'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
      return s.copyWith(
        roadmapSummary: roadmapSummary,
        topicRoadmap: topicRoadmap,
        reviewQueue: reviewQueue,
      );
    });
    await fetchRewardProfile();
  }
}
