import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_agency_provider.dart';
import '../models/collection_agency_model.dart';

class AddEditCollectionAgencyScreen extends StatefulWidget {
  final CollectionAgency? agency;

  const AddEditCollectionAgencyScreen({super.key, this.agency});

  static const routeName = '/add-edit-collection-agency';

  @override
  State<AddEditCollectionAgencyScreen> createState() => _AddEditCollectionAgencyScreenState();
}

class _AddEditCollectionAgencyScreenState extends State<AddEditCollectionAgencyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _agencyNameController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _fileNumberController;
  bool _isActive = true;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.agency != null;
    _agencyNameController = TextEditingController(text: _isEditing ? widget.agency!.agencyName : '');
    _contactPersonController = TextEditingController(text: _isEditing ? widget.agency!.contactPerson : '');
    _phoneNumberController = TextEditingController(text: _isEditing ? widget.agency!.phoneNumber : '');
    _emailController = TextEditingController(text: _isEditing ? widget.agency!.email : '');
    _addressController = TextEditingController(text: _isEditing ? widget.agency!.address : '');
    _fileNumberController = TextEditingController(text: _isEditing ? widget.agency!.fileNumber : '');
    _isActive = _isEditing ? widget.agency!.isActive : true;
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _contactPersonController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _fileNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    final provider = Provider.of<CollectionAgencyProvider>(context, listen: false);
    bool success = false;
    String successMessage = '';
    String errorMessage = '';

    final currentAgency = CollectionAgency(
      agencyID: _isEditing ? widget.agency!.agencyID : null,
      agencyName: _agencyNameController.text.trim(),
      contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim().isEmpty ? null : _phoneNumberController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      fileNumber: _fileNumberController.text.trim().isEmpty ? null : _fileNumberController.text.trim(),
      isActive: _isActive,
    );

    try {
      if (_isEditing) {
        success = await provider.updateAgency(currentAgency);
        successMessage = 'Agency updated successfully!';
        errorMessage = provider.errorMessage ?? 'Failed to update agency.';
      } else {
        success = await provider.addAgency(currentAgency);
        successMessage = 'Agency added successfully!';
        errorMessage = provider.errorMessage ?? 'Failed to add agency. Name might already exist.';
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
        title: Text(_isEditing ? 'Edit Collection Agency' : 'Add New Agency'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextFormField(controller: _agencyNameController, label: 'Agency Name*', icon: Icons.business_outlined),
              _buildTextFormField(controller: _contactPersonController, label: 'Contact Person', icon: Icons.person_outline),
              _buildTextFormField(controller: _phoneNumberController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              _buildTextFormField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              _buildTextFormField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
              _buildTextFormField(controller: _fileNumberController, label: 'File Number (Optional)', icon: Icons.folder_shared_outlined),
              SwitchListTile(
                title: const Text('Is Active'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: Icon(_isEditing ? Icons.save_alt_outlined : Icons.add_business_outlined),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Agency'),
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
    String? Function(String?)? validator,
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
          return validator?.call(value);
        },
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }
}
