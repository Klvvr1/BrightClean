const generalServiceNames = [
  'الملابس',
  'السجاد والمفروشات',
  'السيارات',
  'تنظيف المكيفات',
  'عاملات النظافة',
  'تنظيف الخزانات',
  'غسيل الألواح الشمسية',
];

String generalServiceNameForDetail(String serviceType, String optionId) {
  switch (optionId) {
    case 'wash_iron':
    case 'wash_only':
    case 'iron_only':
      return 'الملابس';
    case 'furniture_wash':
      return 'السجاد والمفروشات';
    case 'car_exterior':
    case 'car_full':
      return 'السيارات';
    case 'ac_indoor':
    case 'ac_full':
      return 'تنظيف المكيفات';
    case 'maid_hourly':
      return 'عاملات النظافة';
    case 'tank_regular':
      return 'تنظيف الخزانات';
    case 'solar_dust':
    case 'solar_soap':
    case 'solar_polish':
      return 'غسيل الألواح الشمسية';
  }

  if (generalServiceNames.contains(serviceType)) {
    return serviceType;
  }
  if (serviceType.contains('ملابس')) return 'الملابس';
  if (serviceType.contains('سجاد') || serviceType.contains('مفروشات')) {
    return 'السجاد والمفروشات';
  }
  if (serviceType.contains('سيار')) return 'السيارات';
  if (serviceType.contains('مكيف')) return 'تنظيف المكيفات';
  if (serviceType.contains('عاملات')) return 'عاملات النظافة';
  if (serviceType.contains('خزان')) return 'تنظيف الخزانات';
  if (serviceType.contains('شمس')) return 'غسيل الألواح الشمسية';

  return serviceType;
}

int resolveGeneralServiceId(
  String serviceType,
  String optionId,
  Map<int, String> serviceNamesById,
) {
  final targetName = generalServiceNameForDetail(serviceType, optionId).trim();
  for (final entry in serviceNamesById.entries) {
    if (entry.value.trim() == targetName) {
      return entry.key;
    }
  }
  return 0;
}
