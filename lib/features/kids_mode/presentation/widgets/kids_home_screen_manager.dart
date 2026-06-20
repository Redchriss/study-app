import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:genui/genui.dart' hide TextPart;
import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_state_provider.dart';
import 'kids_lesson_actions.dart';
import '../genui/kids_catalog.dart';
import 'kids_home_screen_fetcher.dart';
import '../../../agent/presentation/screens/agent_stream_service.dart';
import '../../../agent/presentation/providers/agent_state.dart';

class KidsHomeScreenManager {
  final WidgetRef ref;
  late final KidsLessonActions actions;
  BuildContext Function() _contextFn = () => throw UnimplementedError();
  bool Function() _mountedFn = () => true;
  late final SurfaceController surfaceController;
  late final A2uiTransportAdapter _transport;
  late final Conversation conversation;
  late final Catalog catalog;
  late final AgentStreamService _streamService;
  late final KidsHomeScreenFetcher fetcher;

  KidsHomeScreenManager(this.ref) {
    actions = KidsLessonActions(this);
    catalog = buildKidsCatalog();
    surfaceController = SurfaceController(catalogs: [catalog]);
    fetcher = KidsHomeScreenFetcher(
      ref: ref,
      catalog: catalog,
      mountedFn: _mountedFn,
      contextFn: _contextFn,
    );
    _transport = A2uiTransportAdapter(onSend: fetcher.sendAndReceive);
    _streamService = AgentStreamService();
    fetcher.attachServices(
      transport: _transport,
      streamService: _streamService,
    );
    conversation =
        Conversation(controller: surfaceController, transport: _transport);
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

  Future<void> fetchSubjects() => fetcher.fetchSubjects();
  Future<void> fetchDailySummary() => fetcher.fetchDailySummary();
  Future<void> fetchRewardProfile() => fetcher.fetchRewardProfile();
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

  Future<void> fetchRoadmap(String subjectId, int standard) =>
      fetcher.fetchRoadmap(subjectId, standard);
}
