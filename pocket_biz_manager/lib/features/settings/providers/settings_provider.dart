import 'package:flutter/foundation.dart';
import '../../../core/models/company_settings_model.dart';
import '../../../core/database/database_service.dart';

class SettingsProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  CompanySettings? _currentSettings;
  bool _isLoading = false;
  String? _errorMessage;

  CompanySettings? get currentSettings => _currentSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SettingsProvider() {
    loadSettings();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    _setLoading(true);
    try {
      final settingsMap = await _dbService.getCompanySettings();
      if (settingsMap != null) {
        _currentSettings = CompanySettings.fromMap(settingsMap);
      } else {
        // This case should ideally be handled by seeding in DatabaseService._onCreate
        // or by creating default settings if none are found.
        _currentSettings = CompanySettings(); // Create default instance
        // Optionally, try to save these default settings to DB if they truly don't exist
        // await _dbService.updateCompanySettings(_currentSettings!.toMap());
        // For now, we assume _onCreate handles the initial seed.
        debugPrint("No company settings found in DB, using default. Ensure DB is seeded.");
      }
    } catch (e) {
      debugPrint("Error loading company settings: $e");
      _setError("Failed to load company settings.");
      _currentSettings = CompanySettings(); // Fallback to default on error
    }
    _setLoading(false);
  }

  Future<bool> saveSettings(CompanySettings settingsToSave) async {
    _setLoading(true);
    try {
      // The DatabaseService().updateCompanySettings method now ensures SettingID is 1.
      final rowsAffected = await _dbService.updateCompanySettings(settingsToSave.toMap());
      if (rowsAffected > 0) {
        _currentSettings = settingsToSave; // Update local cache
        notifyListeners();
        _setLoading(false);
        return true;
      }
      _setError("Failed to save settings to database.");
    } catch (e) {
      debugPrint("Error saving company settings: $e");
      _setError("An error occurred while saving settings.");
    }
    _setLoading(false);
    return false;
  }

  // Specific method to update invoice prefix, might be called from other places too
  Future<bool> updateInvoicePrefix(String? prefix) async {
    if (_currentSettings == null) {
      await loadSettings(); // Ensure settings are loaded
      if(_currentSettings == null) {
        _setError("Cannot update prefix: settings not loaded.");
        return false;
      }
    }
    CompanySettings updatedSettings = _currentSettings!.copyWith(invoicePrefix: prefix);
    return await saveSettings(updatedSettings);
  }

  // Specific method to update last invoice sequence, usually called internally by SalesProvider
  Future<bool> updateLastInvoiceSequence(int sequence) async {
     if (_currentSettings == null) {
      await loadSettings();
       if(_currentSettings == null) {
        _setError("Cannot update sequence: settings not loaded.");
        return false;
      }
    }
    // Only update if the new sequence is higher or prefix changes
    // This logic might be better placed directly where sequence is incremented (e.g. SalesProvider)
    // to ensure atomicity with invoice creation.
    // For now, this provider method updates it directly.
    CompanySettings updatedSettings = _currentSettings!.copyWith(lastInvoiceSequence: sequence);
    // We might not want to call saveSettings which notifies all listeners for this internal change.
    // Instead, use the specific DB method.
    _setLoading(true);
    try {
      final rowsAffected = await _dbService.updateInvoiceSequenceSettings(_currentSettings!.invoicePrefix, sequence);
      if (rowsAffected > 0) {
        _currentSettings = updatedSettings; // Update local cache
        // No broad notifyListeners() here if this is meant for background update by SalesProvider
        // SalesProvider should handle its own UI updates if needed.
        // However, if settings screen is open, it might need an update.
        // For simplicity now, we will notify.
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch(e) {
      debugPrint("Error updating invoice sequence directly: $e");
      _setError("Failed to update invoice sequence.");
    }
    _setLoading(false);
    return false;
  }
}
