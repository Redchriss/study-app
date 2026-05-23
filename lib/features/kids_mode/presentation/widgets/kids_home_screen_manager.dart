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
import 'kids_lesson_actions.dart';
import '../genui/kids_catalog.dart';
import '../../../ai_tutor/presentation/screens/ai_tutor_stream_service.dart';
import '../../../ai_tutor/presentation/screens/ai_tutor_manager.dart'; // for ConversationItem types

class KidsHomeScreenManager {
  final WidgetRef ref;
  late final KidsLessonActions actions;
  BuildContext Function() _contextFn = () => throw UnimplementedError();
  bool Function() _mountedFn = () => true;

  // GenUI Controllers
  late final SurfaceController surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation conversation;
  late final Catalog catalog;
  late final AiTutorStreamService _streamService;

  KidsHomeScreenManager(this.ref) {
    actions = KidsLessonActions(this);
    catalog = buildKidsCatalog();
    surfaceController = SurfaceController(catalogs: [catalog]);
    _transport = A2uiTransportAdapter(onSend: _sendAndReceive);
    conversation =
        Conversation(controller: surfaceController, transport: _transport);
    _streamService = AiTutorStreamService();

    conversation.events.listen((event) {
      if (!_mountedFn()) return;
      _update((state) {
        if (event is ConversationSurfaceAdded) {
          return state.copyWith(lessonItems: [
            ...state.lessonItems,
            SurfaceItem(surfaceId: event.surfaceId)
          ]);
        } else if (event is ConversationSurfaceRemoved) {
          final newItems = state.lessonItems
              .where((item) =>
                  !(item is SurfaceItem && item.surfaceId == event.surfaceId))
              .toList();
          return state.copyWith(lessonItems: newItems);
        } else if (event is ConversationContentReceived) {
          return state.copyWith(lessonItems: [
            ...state.lessonItems,
            TextItem(text: event.text, isUser: false)
          ]);
        }
        return state;
      });
    });
  }

  Future<void> _sendAndReceive(ChatMessage msg) async {
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
      await _streamService.sendStream(
        text: text,
        sessionId: null,
        studyMode: 'kids_lesson',
        token: auth.token!,
        clientInstructions: clientInstructions,
        httpClient: httpClient,
        onToken: (t) {
          _transport.addChunk(t);
        },
        onAddMessage: (msg) {
          _update((s) => s.copyWith(loading: false));
        },
        onSessionId: (id) {},
        onError: (msg) {
          _update((s) => s.copyWith(loading: false));
          if (_mountedFn()) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        onScrollDown: () {},
      );
    } catch (_) {
      if (!_mountedFn()) return;
      _update((s) => s.copyWith(loading: false));
    } finally {
      httpClient.close();
    }
  }

  void startGenUiLesson(String topicName) {
    _update((s) => s.copyWith(
        loading: true, lessonItems: [], inQuiz: false, currentLesson: null));
    conversation.sendRequest(ChatMessage.user(
        "Teach me about $topicName using the InteractiveMatch and EmojiStoryCard."));
  }

  void attach({
    required BuildContext Function() getContext,
    required bool Function() isMounted,
  }) {
    _contextFn = getContext;
    _mountedFn = isMounted;
  }

  BuildContext get context => _contextFn();
  bool get mounted => _mountedFn();

  KidsHomeState get state => ref.read(kidsHomeStateProvider);

  void _update(KidsHomeState Function(KidsHomeState) cb) {
    ref.read(kidsHomeStateProvider.notifier).apply(cb);
  }

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    return KidGraphqlClient.fromToken(auth.token);
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

  Future<void> fetchTopics(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimaryTopics),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final topics = ((result.data?['primaryTopics'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    _update((s) {
      var selectedTopic = s.selectedTopic;
      if (topics.isEmpty) {
        selectedTopic = null;
      } else if (selectedTopic == null ||
          !topics.any((t) => t['id'] == selectedTopic!['id'])) {
        selectedTopic = topics.first;
      }
      return s.copyWith(topics: topics, selectedTopic: selectedTopic);
    });
  }

  Future<void> fetchSubjectProgress(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidProgress),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    final progress = result.data?['kidProgress'];
    if (progress is Map) {
      _update((s) =>
          s.copyWith(subjectProgress: Map<String, dynamic>.from(progress)));
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
