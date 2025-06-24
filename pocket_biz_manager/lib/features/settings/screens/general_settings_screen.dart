import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../../core/models/company_settings_model.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  static const routeName = '/general-settings';

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _invoicePrefixController;
  // LastInvoiceSequence is typically not edited directly by user from here

  bool _isLoading = false;
  CompanySettings? _initialSettings;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _invoicePrefixController = TextEditingController();

    // Load initial settings into controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (settingsProvider.currentSettings == null) {
        settingsProvider.loadSettings().then((_) {
          if (mounted) {
            _populateControllers(settingsProvider.currentSettings);
          }
        });
      } else {
        _populateControllers(settingsProvider.currentSettings);
      }
    });
  }

  void _populateControllers(CompanySettings? settings) {
    if (settings != null) {
      _initialSettings = settings; // Store initial settings for comparison or reset
      _companyNameController.text = settings.companyName ?? '';
      _addressController.text = settings.address ?? '';
      _phoneController.text = settings.phone ?? '';
      _emailController.text = settings.email ?? '';
      _invoicePrefixController.text = settings.invoicePrefix ?? '';
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _invoicePrefixController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    // Use currentSettings as a base and update with form values
    // This ensures we don't lose other settings like LastInvoiceSequence, CurrencySymbol etc.
    CompanySettings settingsToSave = (settingsProvider.currentSettings ?? CompanySettings()).copyWith(
      companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      invoicePrefix: _invoicePrefixController.text.trim().isEmpty ? null : _invoicePrefixController.text.trim().toUpperCase(),
      // lastInvoiceSequence is managed by SalesProvider or internal logic, not set here directly by user.
    );

    bool success = await settingsProvider.saveSettings(settingsToSave);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(settingsProvider.errorMessage ?? 'Failed to save settings.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a consumer to react to settings changes if needed, or just load once in initState
    // For this form, it's mostly about loading once and saving.
    final settingsProvider = Provider.of<SettingsProvider>(context);
     if (settingsProvider.isLoading && settingsProvider.currentSettings == null) {
      return Scaffold(appBar: AppBar(title: const Text('Company Settings')), body: const Center(child: CircularProgressIndicator()));
    }
    if (settingsProvider.currentSettings == null && !settingsProvider.isLoading) {
       // This means loading finished but currentSettings is still null (e.g. error)
       // _populateControllers would have used defaults if settingsMap was null from DB.
       // So, if _initialSettings is null here, it means the provider's load also resulted in null.
       if(_initialSettings == null) _populateControllers(settingsProvider.currentSettings); // Try to populate with default if still null
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading && _initialSettings == null // Show loader only if initial settings haven't been loaded yet
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextFormField(controller: _companyNameController, label: 'Company Name', icon: Icons.storefront_outlined),
                    _buildTextFormField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 2),
                    _buildTextFormField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    _buildTextFormField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const Divider(height: 30, thickness: 1),
                    Text("Invoice Settings", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    _buildTextFormField(
                      controller: _invoicePrefixController,
                      label: 'Invoice Prefix (e.g., INV, D)',
                      icon: Icons.receipt_long_outlined,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9-]")), // Allow letters, numbers, hyphen
                        LengthLimitingTextInputFormatter(10), // Max 10 chars for prefix
                      ],
                      onChanged: (value) { // Convert to uppercase as user types
                        _invoicePrefixController.value = TextEditingValue(
                          text: value.toUpperCase(),
                          selection: _invoicePrefixController.selection,
                        );
                      }
                    ),
                    ListTile(
                      leading: const Icon(Icons.format_list_numbered_rtl_outlined),
                      title: const Text('Last Invoice Sequence'),
                      subtitle: Text(settingsProvider.currentSettings?.lastInvoiceSequence?.toString() ?? '0'),
                      dense: true,
                    ),
                     ListTile(
                      leading: const Icon(Icons.attach_money_outlined),
                      title: const Text('Currency Symbol'),
                      subtitle: Text(settingsProvider.currentSettings?.currencySymbol ?? 'NAD'),
                      dense: true,
                    ),
                    const SizedBox(height: 24.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      child: const Text('Save All Settings'),
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
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
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
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: (value) {
          // Basic validation: if a field is marked with '*' (though not used in labels here)
          // if (label.endsWith('*') && (value == null || value.trim().isEmpty)) {
          //   return 'This field is required.';
          // }
          if (label == 'Email Address' && value != null && value.trim().isNotEmpty) {
            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
              return 'Please enter a valid email address.';
            }
          }
          if (label == 'Invoice Prefix (e.g., INV, D)' && value != null && value.trim().contains(" ")) {
              return 'Prefix should not contain spaces.';
          }
          return null;
        },
        textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      ),
    );
  }
}
