import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer_model.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  static const routeName = '/add-edit-customer';

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _workPlaceController;
  late TextEditingController _addressController;
  // Balance is not directly editable here, it's calculated from transactions

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.customer != null;
    _nameController = TextEditingController(text: _isEditing ? widget.customer!.customerName : '');
    _idNumberController = TextEditingController(text: _isEditing ? widget.customer!.idNumber : '');
    _phoneController = TextEditingController(text: _isEditing ? widget.customer!.phone : '');
    _emailController = TextEditingController(text: _isEditing ? widget.customer!.email : '');
    _workPlaceController = TextEditingController(text: _isEditing ? widget.customer!.workPlace : '');
    _addressController = TextEditingController(text: _isEditing ? widget.customer!.address : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _workPlaceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save(); // Triggers onSaved for TextFormFields if any
    setState(() => _isLoading = true);

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    bool success = false;
    String successMessage = '';
    String errorMessage = '';

    Customer customerToSave = Customer( // Renamed for clarity
      customerID: _isEditing ? widget.customer!.customerID : null,
      customerName: _nameController.text.trim(),
      idNumber: _idNumberController.text.trim().isEmpty ? null : _idNumberController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      workPlace: _workPlaceController.text.trim().isEmpty ? null : _workPlaceController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      balance: _isEditing ? widget.customer!.balance : 0.0, // Preserve existing balance on edit
    );

    try {
      if (_isEditing) {
        success = await provider.updateCustomer(customerToSave);
        successMessage = 'Customer updated successfully!';
        errorMessage = provider.errorMessage ?? 'Failed to update customer.';
         if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(customerToSave); // Return updated customer
        }
      } else {
        Customer? newCustomer = await provider.addCustomer(customerToSave);
        if (newCustomer != null) {
          success = true;
          customerToSave = newCustomer; // Get customer with ID
          successMessage = 'Customer added successfully!';
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(customerToSave); // Return new customer with ID
          }
        } else {
          success = false;
          errorMessage = provider.errorMessage ?? 'Failed to add customer. Name or phone might already exist.';
        }
      }

      if (!mounted) return;

      if (!success) { // Only show error if not already handled by popping
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
        title: Text(_isEditing ? 'Edit Customer' : 'Add New Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(controller: _nameController, label: 'Customer Name*', icon: Icons.person),
              _buildTextFormField(controller: _idNumberController, label: 'ID Number (National/Passport)', icon: Icons.badge_outlined),
              _buildTextFormField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_iphone, keyboardType: TextInputType.phone),
              _buildTextFormField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              _buildTextFormField(controller: _workPlaceController, label: 'Work Place / Company', icon: Icons.business_outlined),
              _buildTextFormField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 3),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt_outlined : Icons.person_add_alt),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Customer'),
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
    String? Function(String?)? validator, // Custom validator can be passed
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
          // Specific validation for email
          if (label == 'Email Address' && value != null && value.trim().isNotEmpty) {
            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
              return 'Please enter a valid email address.';
            }
          }
          return validator?.call(value); // Call custom validator if provided
        },
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }
}
