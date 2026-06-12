import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';
import 'kid_auth_widgets.dart';
import 'kid_session_manager.dart';

class KidLoginManager {
  late WidgetRef _ref;
  late void Function(VoidCallback) _setStateFn;
  late BuildContext Function() _contextFn;
  late bool Function() _mountedFn;
  GraphQLClient? _client;
  String? parentToken;
  final parentUserCtrl = TextEditingController();
  final parentPassCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final kidPinCtrl = TextEditingController();
  bool parentLoading = false;
  bool creatingKid = false;
  int? newKidStandard;
  String newKidEducationTrack = 'primary';
  String newKidAvatar = '🦊';
  List<dynamic>? children;
  Map<String, String> avatars = {};
  String? error;
  late final KidSessionManager session;

  void refreshToken(String token, Map<String, dynamic> kid) {
    _ref.read(kidTokenProvider.notifier).state = token;
    _ref.read(kidProfileProvider.notifier).state = kid;
    _ref.read(kidAuthStateProvider.notifier).state = KidAuthState(
      isAuthenticated: true,
      childName: kid['childName'] as String? ?? '',
      standard: (kid['standard'] as num?)?.toInt() ?? 1,
      educationTrack: (kid['educationTrack'] as String?) ?? 'primary',
      token: token,
    );
  }

  void clearSession() {
    _ref.read(kidTokenProvider.notifier).state = null;
    _ref.read(kidProfileProvider.notifier).state = null;
    _ref.read(kidAuthStateProvider.notifier).state = const KidAuthState();
  }

  void attach({
    required WidgetRef ref,
    required void Function(VoidCallback) setState,
    required BuildContext Function() getContext,
    required bool Function() isMounted,
  }) {
    _ref = ref;
    _setStateFn = setState;
    _contextFn = getContext;
    _mountedFn = isMounted;
    session = KidSessionManager(this);
  }

  void dispose() {
    parentUserCtrl.dispose();
    parentPassCtrl.dispose();
    nameCtrl.dispose();
    kidPinCtrl.dispose();
  }

  bool get mounted => _mountedFn();
  BuildContext get context => _contextFn();
  void setState(VoidCallback fn) => _setStateFn(fn);

  GraphQLClient _buildClient({String? token}) {
    final t = token ?? parentToken;
    if (_client != null && token == null) return _client!;
    final authLink =
        AuthLink(getToken: () async => t == null ? null : 'Bearer $t');
    final httpLink = HttpLink(AppConfig.graphqlUrl);
    final client =
        GraphQLClient(cache: GraphQLCache(), link: authLink.concat(httpLink));
    if (token == null) _client = client;
    return client;
  }

  Future<void> loginAsParent() async {
    setState(() {
      parentLoading = true;
      error = null;
    });
    try {
      final result = await _buildClient()
          .mutate(MutationOptions(
            document: gql(kTokenAuth),
            variables: {
              'username': parentUserCtrl.text.trim(),
              'password': parentPassCtrl.text
            },
          ))
          .timeout(const Duration(seconds: 25));
      final auth = result.data?['tokenAuth'];
      if (auth != null) {
        final t = auth['token'] as String?;
        if (t == null || t.isEmpty) {
          throw StateError('Missing parent token');
        }
        parentToken = t;
        _client = null;
        await SecureStorage.saveTokens(
            t, auth['refreshToken'] as String? ?? '');
        await fetchChildren();
        return;
      }
      final msg = graphQLErrorMessage(result.exception, 'Invalid credentials');
      if (!mounted) return;
      setState(() {
        error = msg;
        parentLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Kids sign-in is taking too long. Check your connection.';
        parentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Could not sign in right now. Please try again.';
        parentLoading = false;
      });
    }
  }

  Future<void> fetchChildren() async {
    try {
      final result = await _buildClient()
          .query(QueryOptions(document: gql(kMyChildren)))
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      if (result.hasException) {
        setState(() {
          error = graphQLErrorMessage(
              result.exception, 'Could not load learners. Try again.');
          parentLoading = false;
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> avs = {};
      final loadedChildren = (result.data?['myChildren'] as List? ?? [])
          .whereType<Map>()
          .map((kid) => Map<String, dynamic>.from(kid))
          .toList();
      for (final kid in loadedChildren) {
        avs[kid['id'].toString()] =
            prefs.getString('kid_avatar_${kid['id']}') ?? '';
      }
      setState(() {
        children = loadedChildren;
        avatars = avs;
        parentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'Could not load learners. Check your connection.';
        parentLoading = false;
      });
    }
  }

  Future<void> createKid() async {
    if (nameCtrl.text.trim().isEmpty ||
        kidPinCtrl.text.length != 4 ||
        newKidStandard == null) {
      return;
    }
    setState(() => creatingKid = true);
    try {
      final result = await _buildClient()
          .mutate(MutationOptions(
            document: gql(kCreateChildProfile),
            variables: {
              'childName': nameCtrl.text.trim(),
              'standard': newKidStandard!,
              'pinCode': kidPinCtrl.text,
              'educationTrack': newKidEducationTrack
            },
          ))
          .timeout(const Duration(seconds: 25));
      if (!mounted) return;
      setState(() => creatingKid = false);
      if (result.data?['createChildProfile']?['success'] == true) {
        final childId =
            result.data?['createChildProfile']?['child']?['id']?.toString();
        if (childId != null) {
          (await SharedPreferences.getInstance())
              .setString('kid_avatar_$childId', newKidAvatar);
        }
        nameCtrl.clear();
        kidPinCtrl.clear();
        newKidAvatar = '🦊';
        await fetchChildren();
        return;
      }
      final msg = graphQLErrorMessage(
          result.exception,
          result.data?['createChildProfile']?['errors']?.first?.toString() ??
              'Could not add learner. Try again.');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: DesignTokens.error,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => creatingKid = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add learner. Check your connection.'),
          backgroundColor: DesignTokens.error,
        ),
      );
    }
  }
}
