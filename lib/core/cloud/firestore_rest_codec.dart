Map<String, dynamic> encodeFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};
  for (final entry in data.entries) {
    final value = entry.value;
    if (value == null) continue;
    if (value is String) {
      fields[entry.key] = {'stringValue': value};
    } else if (value is int) {
      fields[entry.key] = {'integerValue': '$value'};
    } else if (value is bool) {
      fields[entry.key] = {'booleanValue': value};
    } else if (value is double) {
      fields[entry.key] = {'doubleValue': value};
    }
  }
  return fields;
}

Map<String, dynamic> decodeFirestoreDocument(Map<String, dynamic> document) {
  final fields = document['fields'] as Map<String, dynamic>? ?? {};
  final result = <String, dynamic>{};

  fields.forEach((key, value) {
    final map = value as Map<String, dynamic>;
    if (map.containsKey('stringValue')) {
      result[key] = map['stringValue'];
    } else if (map.containsKey('integerValue')) {
      result[key] = int.parse(map['integerValue'] as String);
    } else if (map.containsKey('booleanValue')) {
      result[key] = map['booleanValue'];
    } else if (map.containsKey('doubleValue')) {
      result[key] = (map['doubleValue'] as num).toDouble();
    }
  });

  return result;
}

String documentIdFromName(String name) => name.split('/').last;
