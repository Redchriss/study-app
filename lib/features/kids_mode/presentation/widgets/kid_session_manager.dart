import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';
import 'kid_auth_widgets.dart';
import 'kid_login_manager.dart';

class KidSessionManager {
  final KidLoginManager mgr;

  KidSessionManager(this.mgr);

  GraphQLClient _buildClient({String? token}) {
    final t = token ?? mgr.parentToken;
    final authLink =
        AuthLink(getToken: () async => t == null ? null : 'Bearer $t');
    final httpLink = HttpLink(AppConfig.graphqlUrl);
    return GraphQLClient(
        cache: GraphQLCache(), link: authLink.concat(httpLink));
  }

  Future<void> loginAsKid(Map<String, dynamic> kid) async {
    showDialog(
      context: mgr.context,
      barrierDismissible: false,
      builder: (_) => KidPinDialog(
        kidName: kid['childName'] as String? ?? 'Kid',
        onSubmit: (pin) async {
          Navigator.pop(mgr.context);
          final result = await _buildClient().mutate(MutationOptions(
            document: gql(kKidLogin),
            variables: {'username': kid['username'], 'pinCode': pin},
          ));
          final data = result.data?['kidLogin'];
          if (data?['success'] == true) {
            final child = data['child'] as Map<String, dynamic>?;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('kid_token', data['token'] as String);
            final rt = data['refreshToken'] as String?;
            if (rt != null && rt.isNotEmpty)
              await prefs.setString('kid_refresh_token', rt);
            await prefs.setString(
              'kid_child_name',
              child?['childName'] as String? ??
                  kid['childName'] as String? ??
                  '',
            );
            await prefs.setInt(
              'kid_standard',
              (child?['standard'] as num?)?.toInt() ??
                  kid['standard'] as int? ??
                  1,
            );
            await prefs.setString(
              'kid_education_track',
              child?['childEducationTrack'] as String? ?? 'primary',
            );
            mgr.refreshToken(data['token'], Map<String, dynamic>.from(kid));
            if (mgr.mounted) mgr.context.go('/kids/learn');
          } else if (mgr.mounted) {
            ScaffoldMessenger.of(mgr.context).showSnackBar(SnackBar(
              content: Text(data?['errors']?.first ?? 'Wrong PIN'),
              backgroundColor: DesignTokens.error,
            ));
          }
        },
      ),
    );
  }

  Future<void> logoutParent() async {
    await SecureStorage.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kid_token');
    await prefs.remove('kid_refresh_token');
    await prefs.remove('kid_child_name');
    await prefs.remove('kid_standard');
    await prefs.remove('kid_education_track');
    if (!mgr.mounted) return;
    mgr.clearSession();
    mgr.setState(() {
      mgr.parentToken = null;
      mgr.children = null;
    });
  }

  Future<void> restoreSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final kidToken = prefs.getString('kid_token');
    final kidName = prefs.getString('kid_child_name');
    final kidStandard = prefs.getInt('kid_standard');
    final kidTrack = prefs.getString('kid_education_track');
    if (!mgr.mounted) return;
    if (kidToken != null &&
        kidToken.isNotEmpty &&
        kidName != null &&
        kidName.isNotEmpty &&
        kidStandard != null) {
      mgr.refreshToken(kidToken, {
        'childName': kidName,
        'standard': kidStandard,
        'educationTrack': kidTrack ?? 'primary'
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mgr.mounted) mgr.context.go('/kids/learn');
      });
      return;
    }
    final pt2 = await SecureStorage.getToken();
    if (pt2 != null && pt2.isNotEmpty) {
      mgr.setState(() {
        mgr.parentToken = pt2;
        mgr.parentLoading = true;
        mgr.error = null;
      });
      await mgr.fetchChildren();
    }
  }
}
