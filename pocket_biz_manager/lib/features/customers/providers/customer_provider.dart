import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../../../core/database/database_service.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Customer> get customers => _customers;
  List<Customer> get activeCustomers => _customers.where((c) => true).toList(); // Placeholder
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

  Future<Customer?> addCustomer(Customer customer) async {
    _setLoading(true);
    Customer? newCustomerWithId;
    try {
      // Trim inputs
      final trimmedName = customer.customerName.trim();
      final trimmedPhone = customer.phone?.trim();

      // Check for duplicates by name (case-insensitive)
      if (_customers.any((c) => c.customerName.toLowerCase() == trimmedName.toLowerCase())) {
        _setError("Customer with name '$trimmedName' already exists.");
        _setLoading(false);
        return null;
      }
      // Check for duplicates by phone if phone is not empty
      if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
        if (_customers.any((c) => c.phone == trimmedPhone)) {
          _setError("Customer with phone number '$trimmedPhone' already exists.");
          _setLoading(false);
          return null;
        }
      }

      // Prepare customer data for insertion (using trimmed values)
      final customerToInsert = customer.copyWith(
        customerName: trimmedName,
        phone: trimmedPhone,
        // ensure other fields are also trimmed if necessary, e.g. email, idNumber
        email: customer.email?.trim().isEmpty == true ? null : customer.email?.trim(),
        idNumber: customer.idNumber?.trim().isEmpty == true ? null : customer.idNumber?.trim(),
        workPlace: customer.workPlace?.trim().isEmpty == true ? null : customer.workPlace?.trim(),
        address: customer.address?.trim().isEmpty == true ? null : customer.address?.trim(),
      );

      final id = await _dbService.insertCustomer(customerToInsert.toMap());
      if (id > 0) {
        newCustomerWithId = customerToInsert.copyWith(customerID: id);
        _customers.add(newCustomerWithId);
        _customers.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
        notifyListeners();
      } else {
        _setError("Failed to add customer to the database. No ID returned.");
        newCustomerWithId = null;
      }
    } catch (e) {
      debugPrint("Error adding customer: $e");
      _setError("Failed to add customer due to an exception: $e");
      newCustomerWithId = null;
    }
    _setLoading(false);
    return newCustomerWithId;
  }

  Future<bool> updateCustomer(Customer customer) async {
    _setLoading(true);
    try {
      final trimmedName = customer.customerName.trim();
      final trimmedPhone = customer.phone?.trim();

      bool nameExists = _customers.any((c) =>
          c.customerName.toLowerCase() == trimmedName.toLowerCase() &&
          c.customerID != customer.customerID);
      if (nameExists) {
        _setError("Another customer with name '$trimmedName' already exists.");
        _setLoading(false);
        return false;
      }
       if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
        bool phoneExists = _customers.any((c) => c.phone == trimmedPhone && c.customerID != customer.customerID);
        if (phoneExists) {
          _setError("Another customer with phone number '$trimmedPhone' already exists.");
          _setLoading(false);
          return false;
        }
      }

      final customerToUpdate = customer.copyWith(
        customerName: trimmedName,
        phone: trimmedPhone,
        email: customer.email?.trim().isEmpty == true ? null : customer.email?.trim(),
        idNumber: customer.idNumber?.trim().isEmpty == true ? null : customer.idNumber?.trim(),
        workPlace: customer.workPlace?.trim().isEmpty == true ? null : customer.workPlace?.trim(),
        address: customer.address?.trim().isEmpty == true ? null : customer.address?.trim(),
      );


      final rowsAffected = await _dbService.updateCustomer(customerToUpdate.toMap());
      if (rowsAffected > 0) {
        final index = _customers.indexWhere((c) => c.customerID == customerToUpdate.customerID);
        if (index != -1) {
          _customers[index] = customerToUpdate;
          _customers.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
          notifyListeners();
        }
        _setLoading(false);
        return true;
      }
       _setError("Failed to update customer in database.");
    } catch (e) {
      debugPrint("Error updating customer: $e");
      _setError("Failed to update customer due to an exception: $e");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> deleteCustomer(int customerId) async {
    _setLoading(true);
    try {
      final rowsAffected = await _dbService.deleteCustomer(customerId);
      if (rowsAffected > 0) {
        _customers.removeWhere((c) => c.customerID == customerId);
        notifyListeners();
        _setLoading(false);
        return true;
      }
      _setError("Failed to delete customer from database.");
    } catch (e) {
      debugPrint("Error deleting customer: $e");
      _setError("Failed to delete customer. They might have existing invoices or an error occurred.");
    }
    _setLoading(false);
    return false;
  }

  Future<bool> updateCustomerBalance(int customerId, double changeInBalance, {DatabaseExecutor? txn}) async {
    _setLoading(true); // Consider if this loading state is appropriate for potentially background operations
    try {
      final db = txn ?? await _dbService.database;

      final List<Map<String, dynamic>> customerMaps = await db.query(
        'Customers',
        columns: ['Balance'],
        where: 'CustomerID = ?',
        whereArgs: [customerId],
      );

      if (customerMaps.isEmpty) {
        _setError("Customer with ID $customerId not found for balance update.");
         if (!isDisposed) _setLoading(false); // Check if provider is disposed
        return false;
      }

      final currentBalance = (customerMaps.first['Balance'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + changeInBalance;

      int result = await db.update(
        'Customers',
        {'Balance': newBalance},
        where: 'CustomerID = ?',
        whereArgs: [customerId],
      );

      if (result > 0) {
        final index = _customers.indexWhere((c) => c.customerID == customerId);
        if (index != -1) {
          _customers[index] = _customers[index].copyWith(balance: newBalance);
           if (!isDisposed) notifyListeners();
        }
         if (!isDisposed) _setLoading(false);
        return true;
      }
       _setError("Failed to update customer balance in DB for ID $customerId.");
    } catch (e) {
      debugPrint("Error updating customer balance for $customerId: $e");
      _setError("Failed to update customer balance for ID $customerId due to an exception.");
    }
     if (!isDisposed) _setLoading(false);
    return false;
  }

  bool _isDisposed = false;
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((customer) => customer.customerID == id);
    } catch (e) {
      return null;
    }
  }
}
