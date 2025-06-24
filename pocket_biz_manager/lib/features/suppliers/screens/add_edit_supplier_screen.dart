import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';

class AddEditSupplierScreen extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierScreen({super.key, this.supplier});

  static const routeName = '/add-edit-supplier';

  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  // Balance is not directly editable here

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.supplier != null;
    _nameController = TextEditingController(text: _isEditing ? widget.supplier!.supplierName : '');
    _phoneController = TextEditingController(text: _isEditing ? widget.supplier!.phone : '');
    _emailController = TextEditingController(text: _isEditing ? widget.supplier!.email : '');
    _addressController = TextEditingController(text: _isEditing ? widget.supplier!.address : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    final provider = Provider.of<SupplierProvider>(context, listen: false);
    bool success = false;
    String successMessage = '';
    String errorMessage = '';

    final currentSupplier = Supplier(
      supplierID: _isEditing ? widget.supplier!.supplierID : null,
      supplierName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      balance: _isEditing ? widget.supplier!.balance : 0.0,
    );

    try {
      if (_isEditing) {
        success = await provider.updateSupplier(currentSupplier);
        successMessage = 'Supplier updated successfully!';
        errorMessage = provider.errorMessage ?? 'Failed to update supplier.';
      } else {
        success = await provider.addSupplier(currentSupplier);
        successMessage = 'Supplier added successfully!';
        errorMessage = provider.errorMessage ?? 'Failed to add supplier. Name or phone might already exist.';
      }

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
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
        title: Text(_isEditing ? 'Edit Supplier' : 'Add New Supplier'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(controller: _nameController, label: 'Supplier Name*', icon: Icons.business_center),
              _buildTextFormField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_android, keyboardType: TextInputType.phone),
              _buildTextFormField(controller: _emailController, label: 'Email Address', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
              _buildTextFormField(controller: _addressController, label: 'Address', icon: Icons.location_city_outlined, maxLines: 3),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_as_outlined : Icons.add_business_rounded),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Supplier'),
                      onPressed: _saveForm,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (value) {
          if (label.endsWith('*') && (value == null || value.trim().isEmpty)) {
            return 'This field is required.';
          }
          if (label == 'Email Address' && value != null && value.trim().isNotEmpty) {
            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
              return 'Please enter a valid email address.';
            }
          }
          return null;
        },
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }
}
