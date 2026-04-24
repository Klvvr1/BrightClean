// import 'package:flutter/material.dart';

enum LaundryType {
  clothes('ملابس', 'Clothes'),
  carsBikes('سيارات ودراجات', 'Cars & Bikes'),
  carpets('سجاد', 'Carpets'),
  ac('مكيفات', 'AC'),
  tanks('خزانات', 'Tanks'),
  solarPanels('ألواح شمسية', 'Solar Panels');

  final String title;
  final String englishTitle;

  const LaundryType(this.title, this.englishTitle);
}
