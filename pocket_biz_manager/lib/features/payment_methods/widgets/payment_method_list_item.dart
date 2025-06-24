import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';

class PaymentMethodListItem extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const PaymentMethodListItem({
    super.key,
    required this.paymentMethod,
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
          backgroundColor: paymentMethod.isActive
                           ? theme.primaryColor.withAlpha(50)
                           : Colors.grey.withAlpha(50),
          child: Icon(
            Icons.payment,
            color: paymentMethod.isActive ? theme.primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          paymentMethod.methodName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: paymentMethod.isActive ? theme.textTheme.bodyLarge?.color : Colors.grey,
            decoration: paymentMethod.isActive ? TextDecoration.none : TextDecoration.lineThrough,
          ),
        ),
        subtitle: paymentMethod.description != null && paymentMethod.description!.isNotEmpty
            ? Text(
                paymentMethod.description!,
                style: TextStyle(
                  color: paymentMethod.isActive ? theme.textTheme.bodySmall?.color : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: paymentMethod.isActive,
              onChanged: onToggleActive,
              activeColor: theme.primaryColor,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Delete Payment Method',
            ),
          ],
        ),
      ),
    );
  }
}
