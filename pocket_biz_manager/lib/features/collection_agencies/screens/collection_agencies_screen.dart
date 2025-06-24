import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_agency_provider.dart';
import '../models/collection_agency_model.dart';
import './add_edit_collection_agency_screen.dart';
import '../widgets/collection_agency_list_item.dart';

class CollectionAgenciesScreen extends StatefulWidget {
  const CollectionAgenciesScreen({super.key});

  static const routeName = '/collection-agencies';

  @override
  State<CollectionAgenciesScreen> createState() => _CollectionAgenciesScreenState();
}

class _CollectionAgenciesScreenState extends State<CollectionAgenciesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollectionAgencyProvider>(context, listen: false).fetchAgencies();
    });
  }

  void _navigateToAddEditScreen(BuildContext context, {CollectionAgency? agency}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditCollectionAgencyScreen(agency: agency),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CollectionAgencyProvider provider, CollectionAgency agency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete agency "${agency.agencyName}"?\nThis action cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteAgency(agency.agencyID!);
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final theme = Theme.of(context);
      final message = success
          ? 'Agency "${agency.agencyName}" deleted.'
          : provider.errorMessage ?? 'Failed to delete agency. It might be in use.';
      final bgColor = success ? Colors.green : theme.colorScheme.error;

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: bgColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Collection Agencies'),
      ),
      body: Consumer<CollectionAgencyProvider>(
        builder: (ctx, agencyProvider, child) {
          if (agencyProvider.isLoading && agencyProvider.agencies.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (agencyProvider.errorMessage != null && agencyProvider.agencies.isEmpty) {
            return Center(child: Text(agencyProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
          }
          if (agencyProvider.agencies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No collection agencies found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEditScreen(context),
                    child: const Text('Add First Agency'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => agencyProvider.fetchAgencies(),
            child: ListView.builder(
              itemCount: agencyProvider.agencies.length,
              itemBuilder: (lCtx, index) {
                final agency = agencyProvider.agencies[index];
                return CollectionAgencyListItem(
                  agency: agency,
                  onTap: () => _navigateToAddEditScreen(context, agency: agency),
                  onDelete: () => _confirmDelete(context, agencyProvider, agency),
                  onToggleActive: (value) async {
                     await agencyProvider.toggleAgencyStatus(agency);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(context),
        tooltip: 'Add Collection Agency',
        child: const Icon(Icons.business_center_outlined),
      ),
    );
  }
}
