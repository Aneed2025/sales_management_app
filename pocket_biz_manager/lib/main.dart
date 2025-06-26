import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app_theme.dart';
import 'core/database/database_service.dart';
import 'features/categories/providers/category_provider.dart';
import 'features/payment_methods/providers/payment_method_provider.dart';
import 'features/products/providers/product_provider.dart';
import 'features/collection_agencies/providers/collection_agency_provider.dart';
import 'features/sales/providers/sales_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/suppliers/providers/supplier_provider.dart';
import 'features/settings/providers/settings_provider.dart';

import 'features/categories/screens/categories_screen.dart';
import 'features/payment_methods/screens/payment_methods_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/collection_agencies/screens/collection_agencies_screen.dart';
import 'features/sales/screens/sales_invoices_list_screen.dart';
import 'features/sales/screens/sales_invoice_detail_screen.dart'; // Import for the detail screen
import 'features/customers/screens/customers_screen.dart';
import 'features/suppliers/screens/suppliers_screen.dart';
import 'features/settings/screens/general_settings_screen.dart';
// import 'features/sales/screens/add_edit_sales_invoice_screen.dart'; // Usually navigated from list


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbService = DatabaseService.instance;
  await dbService.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CollectionAgencyProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProxyProvider3<SettingsProvider, ProductProvider, CustomerProvider, SalesProvider>(
          create: (context) => SalesProvider(
            settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
            productProvider: Provider.of<ProductProvider>(context, listen: false),
            customerProvider: Provider.of<CustomerProvider>(context, listen: false),
          ),
          update: (context, settingsProvider, productProvider, customerProvider, previousSalesProvider) =>
              SalesProvider(
            settingsProvider: settingsProvider,
            productProvider: productProvider,
            customerProvider: customerProvider,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'PocketBiz Manager',
        theme: AppTheme.lightTheme,
        home: const PlaceholderScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          CategoriesScreen.routeName: (ctx) => const CategoriesScreen(),
          PaymentMethodsScreen.routeName: (ctx) => const PaymentMethodsScreen(),
          ProductsScreen.routeName: (ctx) => const ProductsScreen(),
          CollectionAgenciesScreen.routeName: (ctx) => const CollectionAgenciesScreen(),
          CustomersScreen.routeName: (ctx) => const CustomersScreen(),
          SuppliersScreen.routeName: (ctx) => const SuppliersScreen(),
          GeneralSettingsScreen.routeName: (ctx) => const GeneralSettingsScreen(),
          SalesInvoicesListScreen.routeName: (ctx) => const SalesInvoicesListScreen(),
          SalesInvoiceDetailScreen.routeName: (ctx) => const SalesInvoiceDetailScreen(), // Added route
        },
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PocketBiz Manager (NAD)'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome! App is in English.'),
              const Text('Currency: NAD'),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(CategoriesScreen.routeName),
                child: const Text('Manage Categories'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(PaymentMethodsScreen.routeName),
                child: const Text('Manage Payment Methods'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(ProductsScreen.routeName),
                child: const Text('Manage Products'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(CollectionAgenciesScreen.routeName),
                child: const Text('Manage Collection Agencies'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(CustomersScreen.routeName),
                child: const Text('Manage Customers'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(SuppliersScreen.routeName),
                child: const Text('Manage Suppliers'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(GeneralSettingsScreen.routeName),
                child: const Text('General Settings'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                onPressed: () {
                  Navigator.of(context).pushNamed(SalesInvoicesListScreen.routeName);
                },
                child: const Text('Sales Invoices'),
              ),
              const SizedBox(height: 10),
              const Text('Next step: Implement Record Sales Payment Screen.'),
            ],
          ),
        ),
      ),
    );
  }
}
