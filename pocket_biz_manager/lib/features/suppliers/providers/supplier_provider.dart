import 'package:flutter/foundation.dart';
import '../models/supplier_model.dart';
import '../../../core/database/database_service.dart';

class SupplierProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SupplierProvider() {
    fetchSuppliers();
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

  Future<void> fetchSuppliers() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllSuppliers();
      _suppliers = maps.map((map) => Supplier.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching suppliers: $e");
      _setError("Failed to load suppliers.");
      _suppliers = [];
    }
    _setLoading(false);
  }

  Future<bool> addSupplier(Supplier supplier) async {
    _setLoading(true);
    try {
      // Optional: Check for duplicates by name or phone (case-insensitive)
      bool nameExists = _suppliers.any((s) => s.supplierName.toLowerCase() == supplier.supplierName.trim().toLowerCase());
      if (nameExists) {
        _setError("Supplier with name '${supplier.supplierName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }
      if (supplier.phone != null && supplier.phone!.trim().isNotEmpty) {
        bool phoneExists = _suppliers.any((s) => s.phone == supplier.phone!.trim());
        if (phoneExists) {
          _setError("Supplier with phone number '${supplier.phone!.trim()}' already exists.");
          _setLoading(false);
          return false;
        }
      }

      final id = await _dbService.insertSupplier(supplier.toMap());
      if (id > 0) {
        final newSupplier = supplier.copyWith(supplierID: id);
        _suppliers.add(newSupplier);
        _suppliers.sort((a, b) => a.supplierName.toLowerCase().compareTo(b.supplierName.toLowerCase()));
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error adding supplier: $e");
      _setError("Failed to add supplier.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    _setLoading(true);
    try {
      // Optional: Check for duplicates by name or phone (case-insensitive, excluding itself)
      bool nameExists = _suppliers.any((s) =>
          s.supplierName.toLowerCase() == supplier.supplierName.trim().toLowerCase() &&
          s.supplierID != supplier.supplierID);
      if (nameExists) {
        _setError("Another supplier with name '${supplier.supplierName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }
      if (supplier.phone != null && supplier.phone!.trim().isNotEmpty) {
        bool phoneExists = _suppliers.any((s) => s.phone == supplier.phone!.trim() && s.supplierID != supplier.supplierID);
        if (phoneExists) {
          _setError("Another supplier with phone number '${supplier.phone!.trim()}' already exists.");
          _setLoading(false);
          return false;
        }
      }

      final rowsAffected = await _dbService.updateSupplier(supplier.toMap());
      if (rowsAffected > 0) {
        final index = _suppliers.indexWhere((s) => s.supplierID == supplier.supplierID);
        if (index != -1) {
          _suppliers[index] = supplier;
          _suppliers.sort((a, b) => a.supplierName.toLowerCase().compareTo(b.supplierName.toLowerCase()));
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating supplier: $e");
      _setError("Failed to update supplier.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteSupplier(int supplierId) async {
    _setLoading(true);
    // IMPORTANT: Check if supplier is linked to any Purchase_Bills before deleting
    try {
      final rowsAffected = await _dbService.deleteSupplier(supplierId);
      if (rowsAffected > 0) {
        _suppliers.removeWhere((s) => s.supplierID == supplierId);
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting supplier: $e");
      _setError("Failed to delete supplier. They might have existing bills.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateSupplierBalance(int supplierId, double changeInBalance) async {
    _setLoading(true);
    try {
      final supplierMap = await _dbService.getSupplierById(supplierId);
      if (supplierMap != null) {
        Supplier supplier = Supplier.fromMap(supplierMap);
        double newBalance = supplier.balance + changeInBalance; // If company owes more, balance increases. If company pays, changeInBalance is negative.
        int result = await _dbService.updateSupplierBalance(supplierId, newBalance);
        if(result > 0){
            final index = _suppliers.indexWhere((s) => s.supplierID == supplierId);
            if (index != -1) {
                _suppliers[index] = _suppliers[index].copyWith(balance: newBalance);
                notifyListeners();
            }
             _setLoading(false);
            return true;
        }
      }
    } catch (e) {
      debugPrint("Error updating supplier balance: $e");
      _setError("Failed to update supplier balance.");
    }
    _setLoading(false);
    return false;
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((supplier) => supplier.supplierID == id);
    } catch (e) {
      return null;
    }
  }
}
