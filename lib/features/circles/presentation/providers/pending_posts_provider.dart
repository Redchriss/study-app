import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PendingStatus { submitting, confirmed, failed }

class PendingEntry {
  final String tempId;
  final String type;
  final String groupKey;
  final String? parentId;
  Map<String, dynamic> data;
  PendingStatus status;
  String? error;

  PendingEntry({
    required this.tempId,
    required this.type,
    required this.groupKey,
    this.parentId,
    required this.data,
    this.status = PendingStatus.submitting,
    this.error,
  });
}

class PendingPostsNotifier extends StateNotifier<List<PendingEntry>> {
  PendingPostsNotifier() : super([]);

  void add(PendingEntry entry) {
    state = [...state, entry];
  }

  void confirm(String tempId, Map<String, dynamic> updatedData) {
    state = state.map((e) {
      if (e.tempId == tempId) {
        e.data = updatedData;
        e.status = PendingStatus.confirmed;
        e.error = null;
      }
      return e;
    }).toList();
  }

  void fail(String tempId, String errorMessage) {
    state = state.map((e) {
      if (e.tempId == tempId) {
        e.status = PendingStatus.failed;
        e.error = errorMessage;
      }
      return e;
    }).toList();
  }

  void remove(String tempId) {
    state = state.where((e) => e.tempId != tempId).toList();
  }

  List<PendingEntry> forGroup(String groupKey) {
    return state.where((e) => e.groupKey == groupKey).toList();
  }

  void removeByGroup(String groupKey) {
    state = state.where((e) => e.groupKey != groupKey).toList();
  }
}

final pendingPostsProvider =
    StateNotifierProvider<PendingPostsNotifier, List<PendingEntry>>((ref) {
  return PendingPostsNotifier();
});
