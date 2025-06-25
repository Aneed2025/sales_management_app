import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../../../core/database/database_service.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Customer> get customers => _customers;
  List<Customer> get activeCustomers => _customers.where((c) => true).toList(); // Assuming no IsActive field in Customer model yet, or filter if added
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CustomerProvider() {
    fetchCustomers();
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

  Future<void> fetchCustomers() async {
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> maps = await _dbService.getAllCustomers();
      _customers = maps.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      debugPrint("Error fetching customers: $e");
      _setError("Failed to load customers.");
      _customers = [];
    }
    _setLoading(false);
  }

  Future<Customer?> addCustomer(Customer customer) async { // Return Customer?
    _setLoading(true);
    Customer? newCustomerWithId;
    try {
      // Optional: Check for duplicates by name or phone (case-insensitive)
      bool nameExists = _customers.any((c) => c.customerName.toLowerCase() == customer.customerName.trim().toLowerCase());
      if (nameExists) {
        _setError("Customer with name '${customer.customerName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }
      if (customer.phone != null && customer.phone!.trim().isNotEmpty) {
        bool phoneExists = _customers.any((c) => c.phone == customer.phone!.trim());
        if (phoneExists) {
          _setError("Customer with phone number '${customer.phone!.trim()}' already exists.");
          _setLoading(false);
          return false;
        }
      }


      final id = await _dbService.insertCustomer(customer.toMap());
      if (id > 0) {
        final newCustomer = customer.copyWith(customerID: id);
        newCustomerWithId = customer.copyWith(customerID: id);
        _customers.add(newCustomerWithId);
        _customers.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error adding customer: $e");
      _setError("Failed to add customer.");
      newCustomerWithId = null; // Ensure null on error
    }
    _setLoading(false);
    return newCustomerWithId; // Return the customer object or null
  }

  Future<bool> updateCustomer(Customer customer) async {
    _setLoading(true);
    try {
      // Optional: Check for duplicates by name or phone (case-insensitive, excluding itself)
      bool nameExists = _customers.any((c) =>
          c.customerName.toLowerCase() == customer.customerName.trim().toLowerCase() &&
          c.customerID != customer.customerID);
      if (nameExists) {
        _setError("Another customer with name '${customer.customerName.trim()}' already exists.");
        _setLoading(false);
        return false;
      }
       if (customer.phone != null && customer.phone!.trim().isNotEmpty) {
        bool phoneExists = _customers.any((c) => c.phone == customer.phone!.trim() && c.customerID != customer.customerID);
        if (phoneExists) {
          _setError("Another customer with phone number '${customer.phone!.trim()}' already exists.");
          _setLoading(false);
          return false;
        }
      }

      final rowsAffected = await _dbService.updateCustomer(customer.toMap());
      if (rowsAffected > 0) {
        final index = _customers.indexWhere((c) => c.customerID == customer.customerID);
        if (index != -1) {
          _customers[index] = customer;
          _customers.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating customer: $e");
      _setError("Failed to update customer.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteCustomer(int customerId) async {
    _setLoading(true);
    // IMPORTANT: Check if customer is linked to any Sales_Invoices before deleting
    try {
      final rowsAffected = await _dbService.deleteCustomer(customerId);
      if (rowsAffected > 0) {
        _customers.removeWhere((c) => c.customerID == customerId);
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting customer: $e");
      _setError("Failed to delete customer. They might have existing invoices.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateCustomerBalance(int customerId, double changeInBalance) async {
    // This method might be more complex: fetch customer, update balance, save.
    // Or DatabaseService.updateCustomerBalance could adjust directly.
    // For now, let's assume DatabaseService.updateCustomerBalance updates the balance by setting a new value.
    // We need to fetch the current balance first.
    _setLoading(true);
    try {
      final customerMap = await _dbService.getCustomerById(customerId);
      if (customerMap != null) {
        Customer customer = Customer.fromMap(customerMap);
        double newBalance = customer.balance + changeInBalance;
        int  result = await _dbService.updateCustomerBalance(customerId, newBalance);
        if(result > 0){
            final index = _customers.indexWhere((c) => c.customerID == customerId);
            if (index != -1) {
                _customers[index] = _customers[index].copyWith(balance: newBalance);
                notifyListeners();
            }
             _setLoading(false);
            return true;
        }
      }
    } catch (e) {
      debugPrint("Error updating customer balance: $e");
      _setError("Failed to update customer balance.");
    }
    _setLoading(false);
    return false;
  }


  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.customerID == id);
    } catch (e) {
      // If not in list, could try fetching from DB, but for now, assume it should be in the list if valid
      // fetchCustomers(); // This might be too aggressive
      return null;
    }
  }
}
