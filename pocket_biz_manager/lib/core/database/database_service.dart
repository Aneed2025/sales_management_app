import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // For join path
import 'package:path_provider/path_provider.dart'; // For getApplicationDocumentsDirectory
import 'dart:io'; // For Directory

class DatabaseService {
  static const String _databaseName = "pocket_biz.db";
  static const int _databaseVersion = 1;

  // Making it a singleton class
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
      // onUpgrade: _onUpgrade, // TODO: Implement migrations later if schema changes
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users (
        UserID INTEGER PRIMARY KEY AUTOINCREMENT,
        Username TEXT UNIQUE,
        PasswordHash TEXT,
        FullName TEXT,
        Email TEXT,
        IsActive INTEGER DEFAULT 1 -- Boolean: 0 for false, 1 for true
      )
    ''');

    await db.execute('''
      CREATE TABLE Company_Settings (
        SettingID INTEGER PRIMARY KEY AUTOINCREMENT, -- Should only have one row
        CompanyName TEXT,
        Address TEXT,
        Phone TEXT,
        Email TEXT,
        CurrencySymbol TEXT DEFAULT 'NAD',
        LogoURL TEXT
      )
    ''');
    // Seed initial company settings (one row)
    await db.insert('Company_Settings', {'CurrencySymbol': 'NAD'});


    await db.execute('''
      CREATE TABLE Categories (
        CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
        CategoryName TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE Products (
        ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
        ProductName TEXT NOT NULL,
        SKU TEXT UNIQUE,
        Barcode TEXT UNIQUE,
        Description TEXT,
        CategoryID INTEGER,
        PurchasePrice REAL DEFAULT 0, -- Using REAL for numeric types
        SalePrice REAL DEFAULT 0,
        CurrentStock REAL DEFAULT 0,
        MinStockLevel REAL DEFAULT 0,
        ProductImageURL TEXT,
        IsActive INTEGER DEFAULT 1,
        FOREIGN KEY (CategoryID) REFERENCES Categories (CategoryID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Customers (
        CustomerID INTEGER PRIMARY KEY AUTOINCREMENT,
        CustomerName TEXT NOT NULL,
        IDNumber TEXT,
        Phone TEXT,
        Email TEXT,
        WorkPlace TEXT,
        Address TEXT,
        Balance REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales_Invoices (
        InvoiceID INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceNumber TEXT NOT NULL UNIQUE,
        InvoiceDate TEXT NOT NULL,
        CustomerID INTEGER NOT NULL,
        TotalAmount REAL NOT NULL DEFAULT 0,
        AmountPaid REAL NOT NULL DEFAULT 0,
        BalanceDue REAL NOT NULL DEFAULT 0,
        PaymentStatus TEXT NOT NULL DEFAULT 'Unpaid',
        CreatedByUserID INTEGER,
        Notes TEXT,
        IsInstallment INTEGER NOT NULL DEFAULT 0,
        NumberOfInstallments INTEGER,
        DefaultInstallmentAmount REAL,
        IsInCollection INTEGER NOT NULL DEFAULT 0,
        DateSentToCollection TEXT,
        CollectionAgencyID INTEGER,
        FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID),
        FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID),
        FOREIGN KEY (CollectionAgencyID) REFERENCES Collection_Agencies (AgencyID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Invoice_Installments (
        InstallmentID INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceID INTEGER NOT NULL,
        InstallmentNumber INTEGER NOT NULL,
        DueDate TEXT NOT NULL, -- User sets first due date, subsequent are monthly
        AmountDue REAL NOT NULL, -- Specific amount for this installment
        AmountPaid REAL NOT NULL DEFAULT 0,
        Status TEXT NOT NULL DEFAULT 'Pending', -- "Pending", "Partially Paid", "Paid"
        FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales_Invoice_Items (
        InvoiceItemID INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity REAL NOT NULL,
        UnitPrice REAL NOT NULL,
        LineTotal REAL NOT NULL, -- Quantity * UnitPrice
        FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Payment_Methods (
        PaymentMethodID INTEGER PRIMARY KEY AUTOINCREMENT,
        MethodName TEXT NOT NULL UNIQUE,
        Description TEXT,
        IsActive INTEGER DEFAULT 1
      )
    ''');
    // Seed some default payment methods
    await db.insert('Payment_Methods', {'MethodName': 'Cash', 'IsActive': 1});
    await db.insert('Payment_Methods', {'MethodName': 'Bank Transfer', 'IsActive': 1});


    await db.execute('''
      CREATE TABLE Sales_Payments (
        PaymentID INTEGER PRIMARY KEY AUTOINCREMENT,
        InvoiceID INTEGER NOT NULL,
        CustomerID INTEGER NOT NULL,
        PaymentDate TEXT NOT NULL,
        Amount REAL NOT NULL,
        PaymentMethodID INTEGER NOT NULL,
        CollectedByAgency INTEGER NOT NULL DEFAULT 0, -- 1 if collected by agency, 0 otherwise
        AppliedToInstallmentID INTEGER, -- FK to Invoice_Installments, NULLABLE
        Notes TEXT,
        FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID),
        FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID),
        FOREIGN KEY (PaymentMethodID) REFERENCES Payment_Methods (PaymentMethodID),
        FOREIGN KEY (AppliedToInstallmentID) REFERENCES Invoice_Installments (InstallmentID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Collection_Agencies (
        AgencyID INTEGER PRIMARY KEY AUTOINCREMENT,
        AgencyName TEXT NOT NULL,
        ContactPerson TEXT,
        PhoneNumber TEXT,
        Email TEXT,
        Address TEXT,
        FileNumber TEXT,
        IsActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales_Returns (
        ReturnID INTEGER PRIMARY KEY AUTOINCREMENT,
        ReturnDate TEXT NOT NULL,
        InvoiceID INTEGER, -- Original invoice if linked
        CustomerID INTEGER NOT NULL,
        TotalReturnAmount REAL NOT NULL,
        Notes TEXT,
        FOREIGN KEY (InvoiceID) REFERENCES Sales_Invoices (InvoiceID),
        FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Sales_Return_Items (
        ReturnItemID INTEGER PRIMARY KEY AUTOINCREMENT,
        ReturnID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity REAL NOT NULL,
        UnitPrice REAL NOT NULL, -- Price at which it was returned
        LineTotal REAL NOT NULL,
        FOREIGN KEY (ReturnID) REFERENCES Sales_Returns (ReturnID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Suppliers (
        SupplierID INTEGER PRIMARY KEY AUTOINCREMENT,
        SupplierName TEXT NOT NULL,
        Phone TEXT,
        Email TEXT,
        Address TEXT,
        Balance REAL DEFAULT 0 -- Positive if you owe the supplier
      )
    ''');

    await db.execute('''
      CREATE TABLE Purchase_Bills (
        BillID INTEGER PRIMARY KEY AUTOINCREMENT,
        BillNumber TEXT, -- Supplier's invoice number
        BillDate TEXT NOT NULL,
        SupplierID INTEGER NOT NULL,
        TotalAmount REAL DEFAULT 0,
        AmountPaid REAL DEFAULT 0,
        BalanceDue REAL DEFAULT 0,
        PaymentStatus TEXT DEFAULT 'Unpaid',
        CreatedByUserID INTEGER,
        Notes TEXT,
        FOREIGN KEY (SupplierID) REFERENCES Suppliers (SupplierID),
        FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Purchase_Bill_Items (
        BillItemID INTEGER PRIMARY KEY AUTOINCREMENT,
        BillID INTEGER NOT NULL,
        ProductID INTEGER NOT NULL,
        Quantity REAL NOT NULL,
        UnitPrice REAL NOT NULL, -- Cost price
        LineTotal REAL NOT NULL,
        FOREIGN KEY (BillID) REFERENCES Purchase_Bills (BillID) ON DELETE CASCADE,
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Purchase_Payments (
        PurchasePaymentID INTEGER PRIMARY KEY AUTOINCREMENT, -- Renamed from PaymentID for clarity
        BillID INTEGER,
        SupplierID INTEGER NOT NULL,
        PaymentDate TEXT NOT NULL,
        Amount REAL NOT NULL,
        PaymentMethodID INTEGER NOT NULL,
        Notes TEXT,
        FOREIGN KEY (BillID) REFERENCES Purchase_Bills (BillID),
        FOREIGN KEY (SupplierID) REFERENCES Suppliers (SupplierID),
        FOREIGN KEY (PaymentMethodID) REFERENCES Payment_Methods (PaymentMethodID)
      )
    ''');

    await db.execute('''
      CREATE TABLE Inventory_Movements (
        MovementID INTEGER PRIMARY KEY AUTOINCREMENT,
        ProductID INTEGER NOT NULL,
        MovementType TEXT NOT NULL, -- "Purchase", "Sale", "Sales Return", "Purchase Return", "Manual Adjustment In", "Manual Adjustment Out"
        QuantityChange REAL NOT NULL, -- Positive for stock in, negative for stock out
        MovementDate TEXT NOT NULL, -- Timestamp
        RelatedDocumentType TEXT,
        RelatedDocumentID INTEGER,
        StockAfterMovement REAL NOT NULL,
        CreatedByUserID INTEGER,
        Notes TEXT,
        FOREIGN KEY (ProductID) REFERENCES Products (ProductID),
        FOREIGN KEY (CreatedByUserID) REFERENCES Users (UserID)
      )
    ''');

    // Log completion of table creation
    // In a real app, you might use a logger or print for debugging.
    // For this environment, this print won't be visible but signifies the intent.
    // print("Database tables created successfully.");
  }

  // TODO: Implement _onUpgrade for schema migrations in future versions
  // Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   if (oldVersion < 2) {
  //     // await db.execute("ALTER TABLE ...");
  //   }
  // }

  // Helper methods for CRUD operations will be added here later for each table.
  // For example:
  // Future<int> insertCategory(Map<String, dynamic> row) async {
  //   Database db = await instance.database;
  //   return await db.insert('Categories', row);
  // }
  // Future<List<Map<String, dynamic>>> queryAllCategories() async {
  //   Database db = await instance.database;
  //   return await db.query('Categories');
  // }

  // Category Table CRUD Methods
  Future<int> insertCategory(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Categories', row);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    Database db = await instance.database;
    return await db.query('Categories', orderBy: 'CategoryName ASC');
  }

  Future<Map<String, dynamic>?> getCategoryById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Categories',
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateCategory(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['CategoryID'];
    return await db.update(
      'Categories',
      row,
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    Database db = await instance.database;
    // TODO: Before deleting a category, check if it's being used by any products.
    // If it is, prevent deletion or offer to re-assign products.
    // For now, direct delete:
    return await db.delete(
      'Categories',
      where: 'CategoryID = ?',
      whereArgs: [id],
    );
  }

  // PaymentMethod Table CRUD Methods
  Future<int> insertPaymentMethod(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Payment_Methods', row);
  }

  Future<List<Map<String, dynamic>>> getAllPaymentMethods() async {
    Database db = await instance.database;
    // Order by active status first (active ones on top), then by name
    return await db.query('Payment_Methods', orderBy: 'IsActive DESC, MethodName ASC');
  }

  Future<Map<String, dynamic>?> getPaymentMethodById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Payment_Methods',
      where: 'PaymentMethodID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updatePaymentMethod(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['PaymentMethodID'];
    return await db.update(
      'Payment_Methods',
      row,
      where: 'PaymentMethodID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePaymentMethod(int id) async {
    Database db = await instance.database;
    // TODO: Before deleting a payment method, check if it's being used in any transactions.
    // If it is, prevent deletion or offer to mark as inactive instead.
    // For now, direct delete:
    return await db.delete(
      'Payment_Methods',
      where: 'PaymentMethodID = ?',
      whereArgs: [id],
    );
  }

  // Product Table CRUD Methods
  Future<int> insertProduct(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Products', row);
  }

  Future<List<Map<String, dynamic>>> getAllProductsWithCategoryName() async {
    Database db = await instance.database;
    // Joining Products with Categories to get CategoryName
    // Using a LEFT JOIN in case a product somehow has a null CategoryID
    // or the category was deleted (though FK constraint should prevent orphan Product.CategoryID)
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        P.ProductID, P.ProductName, P.SKU, P.Barcode, P.Description, P.CategoryID,
        P.PurchasePrice, P.SalePrice, P.CurrentStock, P.MinStockLevel, P.ProductImageURL, P.IsActive,
        C.CategoryName
      FROM Products P
      LEFT JOIN Categories C ON P.CategoryID = C.CategoryID
      ORDER BY P.ProductName ASC
    ''');
    return maps;
  }

  Future<Map<String, dynamic>?> getProductByIdWithCategoryName(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        P.ProductID, P.ProductName, P.SKU, P.Barcode, P.Description, P.CategoryID,
        P.PurchasePrice, P.SalePrice, P.CurrentStock, P.MinStockLevel, P.ProductImageURL, P.IsActive,
        C.CategoryName
      FROM Products P
      LEFT JOIN Categories C ON P.CategoryID = C.CategoryID
      WHERE P.ProductID = ?
    ''', [id]);

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['ProductID'];
    return await db.update(
      'Products',
      row,
      where: 'ProductID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    Database db = await instance.database;
    // TODO: Before deleting a product, check if it's used in any transactions
    // (Sales_Invoice_Items, Purchase_Bill_Items, Inventory_Movements).
    // If it is, prevent deletion or offer to mark as inactive.
    // For now, direct delete:
    return await db.delete(
      'Products',
      where: 'ProductID = ?',
      whereArgs: [id],
    );
  }

  // Method to update only the stock of a product
  Future<int> updateProductStock(int productId, double newStock) async {
    Database db = await instance.database;
    return await db.update(
      'Products',
      {'CurrentStock': newStock},
      where: 'ProductID = ?',
      whereArgs: [productId],
    );
  }

  // CollectionAgency Table CRUD Methods
  Future<int> insertCollectionAgency(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Collection_Agencies', row);
  }

  Future<List<Map<String, dynamic>>> getAllCollectionAgencies() async {
    Database db = await instance.database;
    return await db.query('Collection_Agencies', orderBy: 'IsActive DESC, AgencyName ASC');
  }

  Future<Map<String, dynamic>?> getCollectionAgencyById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Collection_Agencies',
      where: 'AgencyID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateCollectionAgency(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['AgencyID'];
    return await db.update(
      'Collection_Agencies',
      row,
      where: 'AgencyID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCollectionAgency(int id) async {
    Database db = await instance.database;
    // TODO: Before deleting an agency, check if it's linked to any Sales_Invoices.
    // If so, prevent deletion or offer to unassign/mark as inactive.
    return await db.delete(
      'Collection_Agencies',
      where: 'AgencyID = ?',
      whereArgs: [id],
    );
  }

  // InvoiceInstallment Table CRUD Methods
  Future<int> insertInvoiceInstallment(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Invoice_Installments', row);
  }

  Future<List<Map<String, dynamic>>> getInstallmentsForInvoice(int invoiceID) async {
    Database db = await instance.database;
    return await db.query(
      'Invoice_Installments',
      where: 'InvoiceID = ?',
      whereArgs: [invoiceID],
      orderBy: 'InstallmentNumber ASC',
    );
  }

  Future<int> updateInvoiceInstallment(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['InstallmentID'];
    return await db.update(
      'Invoice_Installments',
      row,
      where: 'InstallmentID = ?',
      whereArgs: [id],
    );
  }

  // deleteInvoiceInstallment might not be commonly used directly,
  // as installments are usually deleted when the parent invoice is deleted (due to ON DELETE CASCADE)
  // or all are deleted/recreated if installment plan changes drastically.
  Future<int> deleteInstallmentsForInvoice(int invoiceID) async {
    Database db = await instance.database;
    return await db.delete(
      'Invoice_Installments',
      where: 'InvoiceID = ?',
      whereArgs: [invoiceID],
    );
  }

  // Customer Table CRUD Methods
  Future<int> insertCustomer(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('Customers', row);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    Database db = await instance.database;
    return await db.query('Customers', orderBy: 'CustomerName ASC');
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Customers',
      where: 'CustomerID = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> updateCustomer(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['CustomerID'];
    return await db.update(
      'Customers',
      row,
      where: 'CustomerID = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    Database db = await instance.database;
    // TODO: Before deleting a customer, check if they are linked to any Sales_Invoices or other transactions.
    // If so, prevent deletion or implement a soft delete (e.g., IsActive flag in Customers table).
    return await db.delete(
      'Customers',
      where: 'CustomerID = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCustomerBalance(int customerId, double newBalance) async {
    Database db = await instance.database;
    return await db.update(
      'Customers',
      {'Balance': newBalance},
      where: 'CustomerID = ?',
      whereArgs: [customerId],
    );
  }
}
