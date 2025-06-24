import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_method_provider.dart';
import '../models/payment_method_model.dart';

class AddEditPaymentMethodScreen extends StatefulWidget {
  final PaymentMethod? paymentMethod; // Null if adding, populated if editing

  const AddEditPaymentMethodScreen({super.key, this.paymentMethod});

  static const routeName = '/add-edit-payment-method';

  @override
  State<AddEditPaymentMethodScreen> createState() => _AddEditPaymentMethodScreenState();
}

class _AddEditPaymentMethodScreenState extends State<AddEditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.paymentMethod != null;
    _nameController = TextEditingController(text: _isEditing ? widget.paymentMethod!.methodName : '');
    _descriptionController = TextEditingController(text: _isEditing ? widget.paymentMethod!.description : '');
    _isActive = _isEditing ? widget.paymentMethod!.isActive : true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    final provider = Provider.of<PaymentMethodProvider>(context, listen: false);
    bool success = false;
    String successMessage = '';
    String errorMessage = '';

    try {
      if (_isEditing) {
        final updatedMethod = widget.paymentMethod!.copyWith(
          methodName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        );
        success = await provider.updatePaymentMethod(updatedMethod);
        successMessage = 'Payment method updated successfully!';
        errorMessage = 'Failed to update payment method. Name might already exist.';
      } else {
        success = await provider.addPaymentMethod(
          _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        );
        successMessage = 'Payment method added successfully!';
        errorMessage = 'Failed to add payment method. Name might already exist.';
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Payment Method' : 'Add New Payment Method'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Method Name*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a method name.';
                  }
                  if (value.trim().length < 2) {
                    return 'Method name must be at least 2 characters long.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveForm(),
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (bool value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt : Icons.add_circle_outline),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Method'),
                      onPressed: _saveForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
