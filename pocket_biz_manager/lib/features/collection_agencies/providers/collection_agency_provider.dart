import 'package:flutter/foundation.dart';
import '../models/collection_agency_model.dart';
import '../../../core/database/database_service.dart';

class CollectionAgencyProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<CollectionAgency> _agencies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CollectionAgency> get agencies => _agencies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CollectionAgencyProvider() {
    fetchAgencies();
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

  Future<void> fetchAgencies() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllCollectionAgencies();
      _agencies = maps.map((map) => CollectionAgency.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching collection agencies: $e");
      _setError("Failed to load collection agencies.");
      _agencies = [];
    }
    _setLoading(false);
  }

  Future<bool> addAgency(CollectionAgency agency) async {
    _setLoading(true);
    try {
      // Optional: Check for duplicates by name (case-insensitive)
      bool exists = _agencies.any((a) => a.agencyName.toLowerCase() == agency.agencyName.trim().toLowerCase());
      if (exists) {
        _setError("Collection agency with name '${agency.agencyName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }

      final id = await _dbService.insertCollectionAgency(agency.toMap());
      if (id > 0) {
        final newAgency = agency.copyWith(agencyID: id);
        _agencies.add(newAgency);
        _agencies.sort((a, b) {
          if (a.isActive == b.isActive) {
            return a.agencyName.toLowerCase().compareTo(b.agencyName.toLowerCase());
          }
          return a.isActive ? -1 : 1;
        });
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error adding collection agency: $e");
      _setError("Failed to add collection agency.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateAgency(CollectionAgency agency) async {
    _setLoading(true);
    try {
      // Optional: Check for duplicates by name (case-insensitive, excluding itself)
      bool exists = _agencies.any((a) =>
          a.agencyName.toLowerCase() == agency.agencyName.trim().toLowerCase() &&
          a.agencyID != agency.agencyID);
      if (exists) {
        _setError("Another collection agency with name '${agency.agencyName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }

      final rowsAffected = await _dbService.updateCollectionAgency(agency.toMap());
      if (rowsAffected > 0) {
        final index = _agencies.indexWhere((a) => a.agencyID == agency.agencyID);
        if (index != -1) {
          _agencies[index] = agency;
          _agencies.sort((a, b) {
            if (a.isActive == b.isActive) {
              return a.agencyName.toLowerCase().compareTo(b.agencyName.toLowerCase());
            }
            return a.isActive ? -1 : 1;
          });
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating collection agency: $e");
      _setError("Failed to update collection agency.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> toggleAgencyStatus(CollectionAgency agency) async {
    final updatedAgency = agency.copyWith(isActive: !agency.isActive);
    return await updateAgency(updatedAgency);
  }

  Future<bool> deleteAgency(int agencyId) async {
    _setLoading(true);
    // IMPORTANT: Check if agency is linked to any Sales_Invoices before deleting
    // This check should ideally be done here or in DatabaseService
    try {
      final rowsAffected = await _dbService.deleteCollectionAgency(agencyId);
      if (rowsAffected > 0) {
        _agencies.removeWhere((a) => a.agencyID == agencyId);
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting collection agency: $e");
      _setError("Failed to delete collection agency. It might be in use.");
    }
    _setLoading(false);
    return false;
  }

  CollectionAgency? getAgencyById(int id) {
    try {
      return _agencies.firstWhere((agency) => agency.agencyID == id);
    } catch (e) {
      return null; // Not found
    }
  }
}
