import 'package:flutter/foundation.dart';
import '../models/payment_method_model.dart';
import '../../../core/database/database_service.dart';

class PaymentMethodProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;

  // Constructor initializes by fetching payment methods
  PaymentMethodProvider() {
    fetchPaymentMethods();
  }

  Future<void> fetchPaymentMethods() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllPaymentMethods();
      _paymentMethods = maps.map((map) => PaymentMethod.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching payment methods: $e");
      _paymentMethods = []; // Reset on error
    }
    _setLoading(false);
  }

  Future<bool> addPaymentMethod(String methodName, {String? description, bool isActive = true}) async {
    _setLoading(true);
    try {
      final trimmedName = methodName.trim();
      // Check for duplicates (case-insensitive)
      bool exists = _paymentMethods.any((pm) => pm.methodName.toLowerCase() == trimmedName.toLowerCase());
      if (exists) {
        debugPrint("Payment method with name '$trimmedName' already exists.");
        _setLoading(false);
        return false; // Indicate failure due to duplication
      }

      PaymentMethod newMethod = PaymentMethod(
        methodName: trimmedName,
        description: description?.trim(),
        isActive: isActive,
      );
      final id = await _dbService.insertPaymentMethod(newMethod.toMap());
      if (id > 0) {
        newMethod = newMethod.copyWith(paymentMethodID: id);
        _paymentMethods.add(newMethod);
        // Sort by IsActive DESC, then MethodName ASC
        _paymentMethods.sort((a, b) {
          if (a.isActive == b.isActive) {
            return a.methodName.toLowerCase().compareTo(b.methodName.toLowerCase());
          }
          return a.isActive ? -1 : 1;
        });
        notifyListeners();
        _setLoading(false);
        return true; // Success
      }
    } catch (e) {
      debugPrint("Error adding payment method: $e");
    }
    _setLoading(false);
    return false; // Failure
  }

  Future<bool> updatePaymentMethod(PaymentMethod method) async {
    _setLoading(true);
    try {
      final trimmedName = method.methodName.trim();
      // Check for duplicates (case-insensitive, excluding itself)
      bool exists = _paymentMethods.any((pm) =>
          pm.methodName.toLowerCase() == trimmedName.toLowerCase() &&
          pm.paymentMethodID != method.paymentMethodID);
      if (exists) {
        debugPrint("Another payment method with name '$trimmedName' already exists.");
        _setLoading(false);
        return false; // Indicate failure due to duplication
      }

      final updatedMethod = method.copyWith(methodName: trimmedName, description: method.description?.trim());
      final rowsAffected = await _dbService.updatePaymentMethod(updatedMethod.toMap());
      if (rowsAffected > 0) {
        final index = _paymentMethods.indexWhere((pm) => pm.paymentMethodID == updatedMethod.paymentMethodID);
        if (index != -1) {
          _paymentMethods[index] = updatedMethod;
          _paymentMethods.sort((a, b) { // Re-sort
            if (a.isActive == b.isActive) {
              return a.methodName.toLowerCase().compareTo(b.methodName.toLowerCase());
            }
            return a.isActive ? -1 : 1;
          });
          notifyListeners();
          _setLoading(false);
          return true; // Success
        }
      }
    } catch (e) {
      debugPrint("Error updating payment method: $e");
    }
    _setLoading(false);
    return false; // Failure
  }

  Future<bool> togglePaymentMethodStatus(PaymentMethod method) async {
    final updatedMethod = method.copyWith(isActive: !method.isActive);
    return await updatePaymentMethod(updatedMethod);
  }

  Future<bool> deletePaymentMethod(int paymentMethodID) async {
    _setLoading(true);
    // IMPORTANT: Add logic here to check if the payment method is used by any transactions.
    // For now, direct deletion.
    try {
      final rowsAffected = await _dbService.deletePaymentMethod(paymentMethodID);
      if (rowsAffected > 0) {
        _paymentMethods.removeWhere((pm) => pm.paymentMethodID == paymentMethodID);
        notifyListeners();
        _setLoading(false);
        return true; // Success
      }
    } catch (e) {
      debugPrint("Error deleting payment method: $e");
    }
    _setLoading(false);
    return false; // Failure
  }

  PaymentMethod? getPaymentMethodById(int id) {
    try {
      return _paymentMethods.firstWhere((pm) => pm.paymentMethodID == id);
    } catch (e) {
      return null; // Not found
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
