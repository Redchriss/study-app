import 'ai_tutor_state.dart';
export 'ai_tutor_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_tutor_notifier.dart';

final aiTutorProvider = NotifierProvider<AiTutorNotifier, AiTutorState>(
  AiTutorNotifier.new,
);
