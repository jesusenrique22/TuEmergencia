import 'package:flutter/material.dart';

import '../../../../core/maps/map_poi_style.dart';
import '../../../catalog/domain/models/catalog_models.dart';

class MapPoiFilterBar extends StatelessWidget {
  final Set<MapPoiType> selected;
  final ValueChanged<MapPoiType> onToggle;

  const MapPoiFilterBar({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MapPoiType.values.map((type) {
        final style = MapPoiStyle.forType(type.apiValue);
        final isSelected = selected.contains(type);
        return FilterChip(
          label: Text(style.label),
          selected: isSelected,
          onSelected: (_) => onToggle(type),
          avatar: Icon(style.icon, size: 18, color: style.color),
        );
      }).toList(),
    );
  }
}
