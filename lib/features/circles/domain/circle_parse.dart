/// Null-safe parsing helpers for Circles GraphQL maps.
///
/// These exist to kill the recurring `BUGS.md` themes of GraphQL force-casts
/// and string-vs-int count mismatches. Always parse community payloads through
/// these instead of casting (`as int`, `as String`) directly.
library;

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

String asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

Map<String, dynamic>? asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

/// Returns a list of maps, skipping any non-map entries safely.
List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return const [];
  final result = <Map<String, dynamic>>[];
  for (final item in value) {
    final map = asMap(item);
    if (map != null) result.add(map);
  }
  return result;
}

/// Parses an ISO-8601 timestamp, returning null when absent or malformed.
DateTime? asDateTime(dynamic value) {
  final raw = asStringOrNull(value);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
