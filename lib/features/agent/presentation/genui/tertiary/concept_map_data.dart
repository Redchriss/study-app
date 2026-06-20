import 'package:genui/genui.dart';

class NodeData {
  final String id;
  final String label;
  final bool isCentral;

  NodeData({required this.id, required this.label, required this.isCentral});

  factory NodeData.fromJson(Map<String, Object?> json) {
    return NodeData(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      isCentral: (json['is_central'] as num?)?.toInt() == 1,
    );
  }
}

class EdgeData {
  final String fromId;
  final String toId;
  final String relationship;

  EdgeData(
      {required this.fromId, required this.toId, required this.relationship});

  factory EdgeData.fromJson(Map<String, Object?> json) {
    return EdgeData(
      fromId: (json['from_id'] as String?) ?? '',
      toId: (json['to_id'] as String?) ?? '',
      relationship: (json['relationship'] as String?) ?? '',
    );
  }
}

class ConceptMapData {
  final String title;
  final List<NodeData> nodes;
  final List<EdgeData> edges;
  final String actionName;
  final JsonMap actionContext;

  ConceptMapData({
    required this.title,
    required this.nodes,
    required this.edges,
    required this.actionName,
    required this.actionContext,
  });

  factory ConceptMapData.fromJson(Map<String, Object?> json) {
    final action = json['nodeExpandAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final nodesRaw = json['nodes'] as List<dynamic>?;
    final edgesRaw = json['edges'] as List<dynamic>?;
    return ConceptMapData(
      title: (json['title'] as String?) ?? '',
      nodes: nodesRaw
              ?.map((e) => NodeData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      edges: edgesRaw
              ?.map((e) => EdgeData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      actionName: (event?['name'] as String?) ?? 'node_expand',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}
