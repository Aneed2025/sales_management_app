import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseService {
  static const String _databaseName = "pocket_biz.db";
  static const int _databaseVersion = 1;

  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // TODO: Implement migrations later
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await txn.execute('''
        CREATE TABLE Users (
          UserID INTEGER PRIMARY KEY AUTOINCREMENT, Username TEXT UNIQUE, PasswordHash TEXT,
          FullName TEXT, Email TEXT, IsActive INTEGER DEFAULT 1
        )
      ''');
      await txn.execute('''
        CREATE TABLE Company_Settings (
          SettingID INTEGER PRIMARY KEY, CompanyName TEXT, Address TEXT, Phone TEXT, Email TEXT,
          CurrencySymbol TEXT DEFAULT 'NAD', LogoURL TEXT, InvoicePrefix TEXT, LastInvoiceSequence INTEGER DEFAULT 0
        )
      ''');
      List<Map> settings = await txn.query('Company_Settings', where: 'SettingID = ?', whereArgs: [1]);
      if (settings.isEmpty) {
        await txn.insert('Company_Settings', {'SettingID': 1, 'CurrencySymbol': 'NAD', 'LastInvoiceSequence': 0});
      }
      await txn.execute('''
        CREATE TABLE Categories (
          CategoryID INTEGER PRIMARY KEY AUTOINCREMENT, CategoryName TEXT NOT NULL UNIQUE
        )
      ''');
      await txn.execute('''
        CREATE TABLE Products (
          ProductID INTEGER PRIMARY KEY AUTOINCREMENT, ProductName TEXT NOT NULL, SKU TEXT UNIQUE,
          Barcode TEXT UNIQUE, Description TEXT, CategoryID INTEGER, PurchasePrice REAL DEFAULT 0,
          SalePrice REAL DEFAULT 0, CurrentStock REAL DEFAULT 0, MinStockLevel REAL DEFAULT 0,
          ProductImageURL TEXT, IsActive INTEGER DEFAULT 1,
          FOREIGN KEY (CategoryID) REFERENCES Categories (CategoryID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Customers (
          CustomerID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerName TEXT NOT NULL, IDNumber TEXT,
          Phone TEXT, Email TEXT, WorkPlace TEXT, Address TEXT, Balance REAL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE Collection_Agencies (
          AgencyID INTEGER PRIMARY KEY AUTOINCREMENT, AgencyName TEXT NOT NULL, ContactPerson TEXT,
          PhoneNumber TEXT, Email TEXT, Address TEXT, FileNumber TEXT, IsActive INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await txn.execute('''
        CREATE TABLE Sales_Invoices (
          InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT, InvoiceNumber TEXT NOT NULL UNIQUE, InvoiceDate TEXT NOT NULL,
          CustomerID INTEGER NOT NULL, TotalAmount REAL NOT NULL DEFAULT 0, AmountPaid REAL NOT NULL DEFAULT 0,
          BalanceDue REAL NOT NULL DEFAULT 0, PaymentStatus TEXT NOT NULL DEFAULT 'Unpaid',
          CreatedByUserID INTEGER, Notes TEXT, IsInstallment INTEGER NOT NULL DEFAULT 0,
          NumberOfInstallments INTEGER, DefaultInstallmentAmount REAL, IsInCollection INTEGER NOT NULL DEFAULT 0,
          DateSentToCollection TEXT, CollectionAgencyID INTEGER,
          FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID),
          FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID),
          FOREIGN KEY (CollectionAgencyID) REFERENCES Collection_Agencies (AgencyID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Invoice_Installments (
          InstallmentID INTEGER PRIMARY KEY AUTOINCREMENT, InvoiceID INTEGER NOT NULL,
          InstallmentNumber INTEGER NOT NULL, DueDate TEXT NOT NULL, AmountDue REAL NOT NULL,
          AmountPaid REAL NOT NULL DEFAULT 0, Status TEXT NOT NULL DEFAULT 'Pending',
          FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID) ON DELETE CASCADE
        )
      ''');
      await txn.execute('''
        CREATE TABLE Sales_Invoice_Items (
          InvoiceItemID INTEGER PRIMARY KEY AUTOINCREMENT, InvoiceID INTEGER NOT NULL, ProductID INTEGER NOT NULL,
          Quantity REAL NOT NULL, UnitPrice REAL NOT NULL, LineTotal REAL NOT NULL,
          FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID) ON DELETE CASCADE,
          FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Payment_Methods (
          PaymentMethodID INTEGER PRIMARY KEY AUTOINCREMENT, MethodName TEXT NOT NULL UNIQUE,
          Description TEXT, IsActive INTEGER DEFAULT 1
        )
      ''');
      await txn.insert('Payment_Methods', {'MethodName': 'Cash', 'IsActive': 1});
      await txn.insert('Payment_Methods', {'MethodName': 'Bank Transfer', 'IsActive': 1});
      await txn.execute('''
        CREATE TABLE Sales_Payments (
          PaymentID INTEGER PRIMARY KEY AUTOINCREMENT, InvoiceID INTEGER NOT NULL, CustomerID INTEGER NOT NULL,
          PaymentDate TEXT NOT NULL, Amount REAL NOT NULL, PaymentMethodID INTEGER NOT NULL,
          CollectedByAgency INTEGER NOT NULL DEFAULT 0, AppliedToInstallmentID INTEGER, Notes TEXT,
          FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID),
          FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID),
          FOREIGN KEY (PaymentMethodID) REFERENCES Payment_Methods (PaymentMethodID),
          FOREIGN KEY (AppliedToInstallmentID) REFERENCES Invoice_Installments (InstallmentID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Sales_Returns (
          ReturnID INTEGER PRIMARY KEY AUTOINCREMENT, ReturnDate TEXT NOT NULL, InvoiceID INTEGER,
          CustomerID INTEGER NOT NULL, TotalReturnAmount REAL NOT NULL, Notes TEXT,
          FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID),
          FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Sales_Return_Items (
          ReturnItemID INTEGER PRIMARY KEY AUTOINCREMENT, ReturnID INTEGER NOT NULL, ProductID INTEGER NOT NULL,
          Quantity REAL NOT NULL, UnitPrice REAL NOT NULL, LineTotal REAL NOT NULL,
          FOREIGN KEY (ReturnID) REFERENCES Sales_Returns (ReturnID) ON DELETE CASCADE,
          FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Suppliers (
          SupplierID INTEGER PRIMARY KEY AUTOINCREMENT, SupplierName TEXT NOT NULL, Phone TEXT,
          Email TEXT, Address TEXT, Balance REAL DEFAULT 0
        )
      ''');
      await txn.execute('''
        CREATE TABLE Purchase_Bills (
          BillID INTEGER PRIMARY KEY AUTOINCREMENT, BillNumber TEXT, BillDate TEXT NOT NULL,
          SupplierID INTEGER NOT NULL, TotalAmount REAL DEFAULT 0, AmountPaid REAL DEFAULT 0,
          BalanceDue REAL DEFAULT 0, PaymentStatus TEXT DEFAULT 'Unpaid', CreatedByUserID INTEGER, Notes TEXT,
          FOREIGN KEY (SupplierID) REFERENCES Suppliers (SupplierID),
          FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Purchase_Bill_Items (
          BillItemID INTEGER PRIMARY KEY AUTOINCREMENT, BillID INTEGER NOT NULL, ProductID INTEGER NOT NULL,
          Quantity REAL NOT NULL, UnitPrice REAL NOT NULL, LineTotal REAL NOT NULL,
          FOREIGN KEY (BillID) REFERENCES Purchase_Bills (BillID) ON DELETE CASCADE,
          FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Purchase_Payments (
          PurchasePaymentID INTEGER PRIMARY KEY AUTOINCREMENT, BillID INTEGER, SupplierID INTEGER NOT NULL,
          PaymentDate TEXT NOT NULL, Amount REAL NOT NULL, PaymentMethodID INTEGER NOT NULL, Notes TEXT,
          FOREIGN KEY (BillID) REFERENCES Purchase_Bills (BillID),
          FOREIGN KEY (SupplierID) REFERENCES Suppliers (SupplierID),
          FOREIGN KEY (PaymentMethodID) REFERENCES Payment_Methods (PaymentMethodID)
        )
      ''');
      await txn.execute('''
        CREATE TABLE Inventory_Movements (
          MovementID INTEGER PRIMARY KEY AUTOINCREMENT, ProductID INTEGER NOT NULL, MovementType TEXT NOT NULL,
          QuantityChange REAL NOT NULL, MovementDate TEXT NOT NULL, RelatedDocumentType TEXT,
          RelatedDocumentID INTEGER, StockAfterMovement REAL NOT NULL, CreatedByUserID INTEGER, Notes TEXT,
          FOREIGN KEY (ProductID) REFERENCES Products (ProductID),
          FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID)
        )
      ''');
    });
  }

  // --- Category ---
  Future<int> insertCategory(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Categories', row); }
  Future<List<Map<String, dynamic>>> getAllCategories() async { Database db = await instance.database; return await db.query('Categories', orderBy: 'CategoryName ASC'); }
  Future<Map<String, dynamic>?> getCategoryById(int id) async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Categories', where: 'CategoryID = ?', whereArgs: [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateCategory(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['CategoryID']; return await db.update('Categories', row, where: 'CategoryID = ?', whereArgs: [id]); }
  Future<int> deleteCategory(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Categories', where: 'CategoryID = ?', whereArgs: [id]); }

  // --- PaymentMethod ---
  Future<int> insertPaymentMethod(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Payment_Methods', row); }
  Future<List<Map<String, dynamic>>> getAllPaymentMethods() async { Database db = await instance.database; return await db.query('Payment_Methods', orderBy: 'IsActive DESC, MethodName ASC'); }
  Future<Map<String, dynamic>?> getPaymentMethodById(int id) async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Payment_Methods', where: 'PaymentMethodID = ?', whereArgs: [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updatePaymentMethod(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['PaymentMethodID']; return await db.update('Payment_Methods', row, where: 'PaymentMethodID = ?', whereArgs: [id]); }
  Future<int> deletePaymentMethod(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Payment_Methods', where: 'PaymentMethodID = ?', whereArgs: [id]); }

  // --- Product ---
  Future<int> insertProduct(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Products', row); }
  Future<List<Map<String, dynamic>>> getAllProductsWithCategoryName() async { Database db = await instance.database; return await db.rawQuery('''
    SELECT P.*, C.CategoryName FROM Products P LEFT JOIN Categories C ON P.CategoryID = C.CategoryID ORDER BY P.ProductName ASC
  '''); }
  Future<Map<String, dynamic>?> getProductByIdWithCategoryName(int id) async { Database db = await instance.database; final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT P.*, C.CategoryName FROM Products P LEFT JOIN Categories C ON P.CategoryID = C.CategoryID WHERE P.ProductID = ?
  ''', [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateProduct(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['ProductID']; return await db.update('Products', row, where: 'ProductID = ?', whereArgs: [id]); }
  Future<int> deleteProduct(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Products', where: 'ProductID = ?', whereArgs: [id]); }
  Future<int> updateProductStock(int productId, double newStock, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.update('Products', {'CurrentStock': newStock}, where: 'ProductID = ?', whereArgs: [productId]); }

  // --- CollectionAgency ---
  Future<int> insertCollectionAgency(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Collection_Agencies', row); }
  Future<List<Map<String, dynamic>>> getAllCollectionAgencies() async { Database db = await instance.database; return await db.query('Collection_Agencies', orderBy: 'IsActive DESC, AgencyName ASC'); }
  Future<Map<String, dynamic>?> getCollectionAgencyById(int id) async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Collection_Agencies', where: 'AgencyID = ?', whereArgs: [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateCollectionAgency(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['AgencyID']; return await db.update('Collection_Agencies', row, where: 'AgencyID = ?', whereArgs: [id]); }
  Future<int> deleteCollectionAgency(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Collection_Agencies', where: 'AgencyID = ?', whereArgs: [id]); }

  // --- InvoiceInstallment ---
  Future<int> insertInvoiceInstallment(Map<String, dynamic> row, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.insert('Invoice_Installments', row); }
  Future<List<Map<String, dynamic>>> getInstallmentsForInvoice(int invoiceID) async { Database db = await instance.database; return await db.query('Invoice_Installments', where: 'InvoiceID = ?', whereArgs: [invoiceID], orderBy: 'InstallmentNumber ASC'); }
  Future<int> updateInvoiceInstallment(Map<String, dynamic> row, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; int id = row['InstallmentID']; return await db.update('Invoice_Installments', row, where: 'InstallmentID = ?', whereArgs: [id]); }
  Future<int> deleteInstallmentsForInvoice(int invoiceID, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.delete('Invoice_Installments', where: 'InvoiceID = ?', whereArgs: [invoiceID]); }

  // --- Customer ---
  Future<int> insertCustomer(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Customers', row); }
  Future<List<Map<String, dynamic>>> getAllCustomers() async { Database db = await instance.database; return await db.query('Customers', orderBy: 'CustomerName ASC'); }
  Future<Map<String, dynamic>?> getCustomerById(int id) async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Customers', where: 'CustomerID = ?', whereArgs: [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateCustomer(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['CustomerID']; return await db.update('Customers', row, where: 'CustomerID = ?', whereArgs: [id]); }
  Future<int> deleteCustomer(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Customers', where: 'CustomerID = ?', whereArgs: [id]); }
  Future<int> updateCustomerBalance(int customerId, double newBalance, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.update('Customers', {'Balance': newBalance}, where: 'CustomerID = ?', whereArgs: [customerId]); }

  // --- Supplier ---
  Future<int> insertSupplier(Map<String, dynamic> row) async { Database db = await instance.database; return await db.insert('Suppliers', row); }
  Future<List<Map<String, dynamic>>> getAllSuppliers() async { Database db = await instance.database; return await db.query('Suppliers', orderBy: 'SupplierName ASC'); }
  Future<Map<String, dynamic>?> getSupplierById(int id) async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Suppliers', where: 'SupplierID = ?', whereArgs: [id]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateSupplier(Map<String, dynamic> row) async { Database db = await instance.database; int id = row['SupplierID']; return await db.update('Suppliers', row, where: 'SupplierID = ?', whereArgs: [id]); }
  Future<int> deleteSupplier(int id) async { Database db = await instance.database; /* TODO: Check usage */ return await db.delete('Suppliers', where: 'SupplierID = ?', whereArgs: [id]); }
  Future<int> updateSupplierBalance(int supplierId, double newBalance, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.update('Suppliers', {'Balance': newBalance}, where: 'SupplierID = ?', whereArgs: [supplierId]); }

  // --- CompanySettings ---
  Future<Map<String, dynamic>?> getCompanySettings() async { Database db = await instance.database; List<Map<String, dynamic>> maps = await db.query('Company_Settings', where: 'SettingID = ?', whereArgs: [1]); if (maps.isNotEmpty) return maps.first; return null; }
  Future<int> updateCompanySettings(Map<String, dynamic> row) async { Database db = await instance.database; if (!row.containsKey('SettingID') || row['SettingID'] != 1) { row['SettingID'] = 1; } return await db.update('Company_Settings', row, where: 'SettingID = ?', whereArgs: [1], conflictAlgorithm: ConflictAlgorithm.replace); }
  Future<int> updateInvoiceSequenceSettings(String? prefix, int sequence, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.update('Company_Settings', {'InvoicePrefix': prefix, 'LastInvoiceSequence': sequence}, where: 'SettingID = ?', whereArgs: [1]); }

  // --- InventoryMovement ---
  Future<int> insertInventoryMovement(Map<String, dynamic> row, {DatabaseExecutor? txn}) async { final db = txn ?? await instance.database; return await db.insert('Inventory_Movements', row); }

  // --- SalesInvoice ---
  Future<List<Map<String, dynamic>>> getAllSalesInvoicesWithCustomerName() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        SI.InvoiceID, SI.InvoiceNumber, SI.InvoiceDate, SI.CustomerID,
        SI.TotalAmount, SI.AmountPaid, SI.BalanceDue, SI.PaymentStatus,
        SI.IsInstallment, SI.NumberOfInstallments, SI.DefaultInstallmentAmount,
        SI.IsInCollection, SI.DateSentToCollection, SI.CollectionAgencyID,
        SI.Notes, SI.CreatedByUserID,
        C.CustomerName
      FROM Sales_Invoices SI
      LEFT JOIN Customers C ON SI.CustomerID = C.CustomerID
      ORDER BY SI.InvoiceDate DESC, SI.InvoiceID DESC
    ''');
    return maps;
  }
  // TODO: Add other SalesInvoice specific methods like getSalesInvoiceByIdWithDetails, updateSalesInvoice, deleteSalesInvoice
}
