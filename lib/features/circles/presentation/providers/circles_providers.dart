import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/circles_repository.dart';

// Re-export the whole repository library so its extension methods
// (reads + content/mod actions) are in scope wherever this provider is used.
export '../../data/circles_repository.dart';

/// The shared [CirclesRepository] — the single backend seam for the whole
/// Circles feature. Screens and notifiers read this instead of issuing raw
/// GraphQL `Query`/`Mutation` widgets.
final circlesRepositoryProvider = Provider<CirclesRepository>((ref) {
  return CirclesRepository(ref);
});
