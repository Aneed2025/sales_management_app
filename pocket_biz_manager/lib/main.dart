import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_theme.dart';
import 'core/database/database_service.dart';
import 'features/categories/providers/category_provider.dart';
import 'features/payment_methods/providers/payment_method_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/categories/screens/categories_screen.dart';
import 'features/payment_methods/screens/payment_methods_screen.dart';
import 'features/products/screens/products_screen.dart';

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
            const Text('Next step: Testing implemented units.'),
          ],
        ),
      ),
    );
  }
}
