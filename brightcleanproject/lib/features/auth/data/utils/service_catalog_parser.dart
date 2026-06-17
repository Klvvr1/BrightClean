Map<int, String> parseServiceCatalogItems(dynamic response) {
  final items = _readCatalogList(response);
  final services = <int, String>{};

  for (final item in items) {
    final idValue = _readFirst(item, [
      'serviceID',
      'serviceId',
      'ServiceID',
      'id',
      'ID',
      'serviceCatalogItemId',
      'serviceCatalogItemID',
    ]);
    final nameValue = _readFirst(item, [
      'serviceName',
      'ServiceName',
      'name',
      'Name',
      'title',
      'Title',
    ]);

    final id =
        idValue is int ? idValue : int.tryParse(idValue?.toString() ?? '');
    final name = nameValue?.toString().trim() ?? '';
    if (id == null || id <= 0 || name.isEmpty) continue;

    services[id] = name;
  }

  return services;
}

List<Map<String, dynamic>> _readCatalogList(dynamic response) {
  if (response is List) return _readMapList(response);
  if (response is Map) {
    final map = response.map((key, value) => MapEntry(key.toString(), value));
    for (final key in const [
      'value',
      'Value',
      'data',
      'Data',
      'services',
      'Services',
      'items',
      'Items',
      'result',
      'Result',
    ]) {
      final value = map[key];
      if (value is List) return _readMapList(value);
    }
  }
  return const [];
}

List<Map<String, dynamic>> _readMapList(List<dynamic> value) {
  return value
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

dynamic _readFirst(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    if (item.containsKey(key)) return item[key];
  }
  return null;
}
