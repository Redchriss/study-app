import 'agent_state.dart';
export 'agent_state.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agent_notifier.dart';

final agentProvider = NotifierProvider<AgentNotifier, AgentState>(
  AgentNotifier.new,
);
