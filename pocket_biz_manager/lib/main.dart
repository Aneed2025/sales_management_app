import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_theme.dart';
// Removed duplicate: import 'package:flutter/material.dart';
// Removed duplicate: import 'package:provider/provider.dart';
// Removed duplicate: import 'app/app_theme.dart'; // app_theme was also duplicated in the error list implicitly
import 'core/database/database_service.dart';
import 'features/categories/providers/category_provider.dart';
import 'features/payment_methods/providers/payment_method_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/categories/screens/categories_screen.dart';
import 'features/payment_methods/screens/payment_methods_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/collection_agencies/screens/collection_agencies_screen.dart';
import 'features/sales/screens/add_edit_sales_invoice_screen.dart';
import 'features/customers/screens/customers_screen.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/suppliers/screens/suppliers_screen.dart'; // Added import for SuppliersScreen
import 'features/suppliers/providers/supplier_provider.dart'; // Added import for SupplierProvider


// Import other providers and screens later // This line can be removed

void main() async { // Made main async for potential async initializations
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database
  final dbService = DatabaseService.instance;
  await dbService.database; // This ensures the DB is opened/created and tables are created on first launch

  // Initialize other services here later

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider will be used to provide various services and state managers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CollectionAgencyProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()), // Added SupplierProvider
        // TODO: Add other providers for features here (Example: ThemeNotifier if used)
        // ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: MaterialApp(
        title: 'PocketBiz Manager', // NAD Currency will be handled by intl
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme, // Optional dark theme
        // themeMode: ThemeMode.system, // Or user-selectable
        home: const PlaceholderScreen(), // Replace with actual home screen later
        debugShowCheckedModeBanner: false, // Hides the debug banner
        // Define routes here later
      ),
    );
  }
}

// A temporary placeholder screen, modified to navigate to various management screens
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketBiz Manager (NAD)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome! App is in English.'),
            const Text('Currency: NAD'),
            const SizedBox(height: 20),
            const Text('Project Setup & DB Schema Implemented.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const CategoriesScreen(),
                ));
              },
              child: const Text('Manage Categories'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const PaymentMethodsScreen(),
                ));
              },
              child: const Text('Manage Payment Methods'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const ProductsScreen(),
                ));
              },
              child: const Text('Manage Products'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const CollectionAgenciesScreen(),
                ));
              },
              child: const Text('Manage Collection Agencies'),
            ),
            const SizedBox(height: 10),
             ElevatedButton(
              onPressed: () {
                // TODO: For a real app, ensure CustomerProvider is initialized and has data
                // For now, we'll assume it's handled or we'll add dummy data for testing.
                // It's better to have a proper CustomerProvider.
                // For testing without a full CustomerProvider, one might pass dummy data or allow
                // manual customer ID entry in AddEditSalesInvoiceScreen for now.
                // For this example, we'll just navigate.
                // Ensure CustomerProvider is provided in MultiProvider if AddEditSalesInvoiceScreen depends on it.
                // We need to create a basic CustomerProvider and Customer model for this to work.
                // Let's assume they will be created.
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const AddEditSalesInvoiceScreen(),
                ));
              },
              child: const Text('Create New Sales Invoice'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const CustomersScreen(),
                ));
              },
              child: const Text('Manage Customers'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const SuppliersScreen(),
                ));
              },
              child: const Text('Manage Suppliers'),
            ),
            const SizedBox(height: 10),
            const Text('Next step: Complete Sales Module.'),
          ],
        ),
      ),
    );
  }
}
