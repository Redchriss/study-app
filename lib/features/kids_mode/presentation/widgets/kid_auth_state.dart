import 'package:flutter_riverpod/flutter_riverpod.dart';

class KidAuthState {
  final bool isAuthenticated;
  final String childName;
  final int standard;
  final String educationTrack;
  final String? token;
  const KidAuthState({
    this.isAuthenticated = false,
    this.childName = '',
    this.standard = 1,
    this.educationTrack = 'primary',
    this.token,
  });
}

final kidTokenProvider = StateProvider<String?>((ref) => null);
final kidProfileProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final kidAuthStateProvider =
    StateProvider<KidAuthState>((ref) => const KidAuthState());
