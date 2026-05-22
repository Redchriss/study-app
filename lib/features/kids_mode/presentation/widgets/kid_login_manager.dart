import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/storage/secure_storage.dart';
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
    final result = await _buildClient().mutate(MutationOptions(
      document: gql(kTokenAuth),
      variables: {
        'username': parentUserCtrl.text.trim(),
        'password': parentPassCtrl.text
      },
    ));
    if (result.data != null && result.data!['tokenAuth'] != null) {
      final t = result.data!['tokenAuth']['token'] as String?;
      if (t != null) {
        parentToken = t;
        _client = null;
        await SecureStorage.saveTokens(
            t, result.data!['tokenAuth']['refreshToken'] as String? ?? '');
      }
      await fetchChildren();
    } else {
      final msg = graphQLErrorMessage(result.exception, 'Invalid credentials');
      setState(() {
        error = msg;
        parentLoading = false;
      });
    }
  }

  Future<void> fetchChildren() async {
    final result =
        await _buildClient().query(QueryOptions(document: gql(kMyChildren)));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> avs = {};
    for (final kid in (result.data?['myChildren'] as List? ?? [])) {
      avs[kid['id'].toString()] =
          prefs.getString('kid_avatar_${kid['id']}') ?? '';
    }
    setState(() {
      children = result.data?['myChildren'] as List? ?? [];
      avatars = avs;
      parentLoading = false;
    });
  }

  Future<void> createKid() async {
    if (nameCtrl.text.trim().isEmpty ||
        kidPinCtrl.text.length != 4 ||
        newKidStandard == null) return;
    setState(() => creatingKid = true);
    final result = await _buildClient().mutate(MutationOptions(
      document: gql(kCreateChildProfile),
      variables: {
        'childName': nameCtrl.text.trim(),
        'standard': newKidStandard!,
        'pinCode': kidPinCtrl.text,
        'educationTrack': newKidEducationTrack
      },
    ));
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
    }
  }
}
