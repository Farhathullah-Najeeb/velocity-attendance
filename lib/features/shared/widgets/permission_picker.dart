import 'package:flutter/material.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/permission_groups.dart';

class PermissionPicker extends StatelessWidget {
  final List<String> availablePermissions;
  final List<String> selectedPermissions;
  final ValueChanged<List<String>> onChanged;

  const PermissionPicker({
    super.key,
    required this.availablePermissions,
    required this.selectedPermissions,
    required this.onChanged,
  });

  Map<String, List<String>> get _grouped {
    final grouped = <String, List<String>>{};
    for (final entry in PermissionGroups.categories.entries) {
      final perms =
          entry.value.where((p) => availablePermissions.contains(p)).toList();
      if (perms.isNotEmpty) grouped[entry.key] = perms;
    }
    final known = PermissionGroups.allPermissions.toSet();
    final uncategorized = availablePermissions
        .where((p) => !known.contains(p))
        .toList();
    if (uncategorized.isNotEmpty) {
      grouped['Other'] = uncategorized;
    }
    return grouped;
  }

  void _toggle(String perm, bool? value) {
    final updated = List<String>.from(selectedPermissions);
    if (value == true) {
      if (!updated.contains(perm)) updated.add(perm);
    } else {
      updated.remove(perm);
    }
    onChanged(updated);
  }

  void _toggleCategory(List<String> perms, bool selectAll) {
    final updated = List<String>.from(selectedPermissions);
    for (final p in perms) {
      if (selectAll) {
        if (!updated.contains(p)) updated.add(p);
      } else {
        updated.remove(p);
      }
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    if (availablePermissions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      shrinkWrap: true,
      children: grouped.entries.map((entry) {
        final perms = entry.value;
        final allSelected = perms.every(selectedPermissions.contains);
        final someSelected =
            perms.any(selectedPermissions.contains) && !allSelected;

        return ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: VelocityColors.secondaryBlack,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _toggleCategory(perms, !allSelected),
                child: Text(
                  allSelected ? 'Clear' : 'Select all',
                  style: const TextStyle(
                    color: VelocityColors.primaryRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          leading: Checkbox(
            value: allSelected
                ? true
                : someSelected
                    ? null
                    : false,
            tristate: true,
            activeColor: VelocityColors.primaryRed,
            onChanged: (_) => _toggleCategory(perms, !allSelected),
          ),
          children: perms
              .map(
                (perm) => CheckboxListTile(
                  title: Text(
                    PermissionGroups.label(perm),
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: selectedPermissions.contains(perm),
                  activeColor: VelocityColors.primaryRed,
                  contentPadding: const EdgeInsets.only(left: 16),
                  dense: true,
                  onChanged: (val) => _toggle(perm, val),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }
}
