import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../../core/graphql/queries/queries.dart';
import '../../data/kid_graphql_client.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kids_reward_panel.dart';
import '../widgets/kids_world_map.dart';
import '../widgets/kid_auth_widgets.dart';

class KidsJourneyScreen extends ConsumerStatefulWidget {
  const KidsJourneyScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.standard,
  });

  final String subjectId;
  final String subjectName;
  final int standard;

  @override
  ConsumerState<KidsJourneyScreen> createState() => _KidsJourneyScreenState();
}

class _KidsJourneyScreenState extends ConsumerState<KidsJourneyScreen> {
  bool _loading = true;
  Map<String, dynamic>? _rewardProfile;
  List<Map<String, dynamic>> _worlds = [];
  String? _error;

  GraphQLClient _client() => KidGraphqlClient.fromToken(ref.read(kidAuthStateProvider).token);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = _client();
    final rewardResult = await client.query(
      QueryOptions(document: gql(kKidRewardProfile), fetchPolicy: FetchPolicy.networkOnly),
    );
    final roadmapResult = await client.query(
      QueryOptions(
        document: gql(kKidSubjectRoadmap),
        variables: {'subjectId': widget.subjectId, 'standard': widget.standard},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (!mounted) return;
    if (rewardResult.hasException || roadmapResult.hasException) {
      setState(() {
        _loading = false;
        _error = rewardResult.exception?.graphqlErrors.firstOrNull?.message ??
            roadmapResult.exception?.graphqlErrors.firstOrNull?.message ??
            'Could not load the journey right now.';
      });
      return;
    }
    setState(() {
      _rewardProfile = rewardResult.data?['kidRewardProfile'] is Map
          ? Map<String, dynamic>.from(rewardResult.data!['kidRewardProfile'] as Map)
          : null;
      final roadmap = roadmapResult.data?['kidSubjectRoadmap'];
      _worlds = ((roadmap is Map ? roadmap['worlds'] : null) as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _loading = false;
    });
  }

  Future<void> _equipCompanion(String code) async {
    final result = await _client().mutate(
      MutationOptions(
        document: gql(kEquipKidCompanion),
        variables: {'code': code},
      ),
    );
    final payload = result.data?['equipKidCompanion'] as Map<String, dynamic>?;
    if (!mounted) return;
    if (payload?['success'] == true && payload?['rewardProfile'] is Map) {
      HapticFeedback.selectionClick();
      setState(() {
        _rewardProfile = Map<String, dynamic>.from(payload!['rewardProfile'] as Map);
      });
      return;
    }
    final message = ((payload?['errors'] as List?) ?? const ['Could not switch companion'])
        .map((item) => item.toString())
        .join(', ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KidsVisualTheme.overlayOn(Theme.of(context)),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('${widget.subjectName} Journey'),
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _error != null
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            if (_rewardProfile != null) ...[
                              KidsRewardPanel(
                                rewardProfile: _rewardProfile!,
                                onCompanionTap: _equipCompanion,
                              ),
                              const SizedBox(height: 16),
                            ],
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'World Map',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KidsVisualTheme.ink),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Finish each stop, return for review, and unlock the next world.',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: KidsVisualTheme.inkMuted),
                                  ),
                                  const SizedBox(height: 16),
                                  KidsWorldMap(
                                    worlds: _worlds,
                                    onTopicTap: (topicId) {
                                      context.pop({'topicId': topicId});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
