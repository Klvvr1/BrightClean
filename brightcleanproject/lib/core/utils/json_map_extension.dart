extension JsonMapReader on Map<String, dynamic> {
  dynamic readValue(String key) => this[key];

  String readString(String key, {String fallback = ''}) {
    return readNullableString(key) ?? fallback;
  }

  String? readNullableString(String key) {
    final value = readValue(key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int readInt(String key, {int fallback = 0}) {
    return readNullableInt(key) ?? fallback;
  }

  int? readNullableInt(String key) {
    final value = readValue(key);
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return int.tryParse(text) ?? double.tryParse(text)?.toInt();
    }
    return null;
  }

  bool readBool(String key, {bool fallback = false}) {
    return readNullableBool(key) ?? fallback;
  }

  bool? readNullableBool(String key) {
    final value = readValue(key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }
    return null;
  }

  DateTime readDateTime(String key) {
    return readNullableDateTime(key) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? readNullableDateTime(String key) {
    final value = readValue(key);
    if (value is DateTime) return value;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }
    return null;
  }

  String readFirstString(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = readNullableString(key);
      if (value != null) return value;
    }
    return fallback;
  }

  int readFirstInt(List<String> keys, {int fallback = 0}) {
    for (final key in keys) {
      final value = readNullableInt(key);
      if (value != null) return value;
    }
    return fallback;
  }

  bool readFirstBool(List<String> keys, {bool fallback = false}) {
    for (final key in keys) {
      final value = readNullableBool(key);
      if (value != null) return value;
    }
    return fallback;
  }

  DateTime? readFirstNullableDateTime(List<String> keys) {
    for (final key in keys) {
      final value = readNullableDateTime(key);
      if (value != null) return value;
    }
    return null;
  }
}
