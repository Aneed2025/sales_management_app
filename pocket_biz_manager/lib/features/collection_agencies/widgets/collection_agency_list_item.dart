import 'package:flutter/material.dart';
import '../models/collection_agency_model.dart';

class CollectionAgencyListItem extends StatelessWidget {
  final CollectionAgency agency;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const CollectionAgencyListItem({
    super.key,
    required this.agency,
    required this.onTap,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: agency.isActive
              ? theme.primaryColor.withAlpha(50)
              : Colors.grey.withAlpha(50),
          child: Icon(
            Icons.business_center_outlined,
            color: agency.isActive ? theme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          agency.agencyName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: agency.isActive ? theme.textTheme.bodyLarge?.color : Colors.grey,
            decoration: agency.isActive ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (agency.contactPerson != null && agency.contactPerson!.isNotEmpty)
              Text('Contact: ${agency.contactPerson}', style: TextStyle(fontSize: 13, color: agency.isActive ? Colors.grey[700] : Colors.grey)),
            if (agency.phoneNumber != null && agency.phoneNumber!.isNotEmpty)
              Text('Phone: ${agency.phoneNumber}', style: TextStyle(fontSize: 13, color: agency.isActive ? Colors.grey[700] : Colors.grey)),
          ],
        ),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: agency.isActive,
              onChanged: onToggleActive,
              activeColor: theme.primaryColor,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Delete Agency',
            ),
          ],
        ),
      ),
    );
  }
}
