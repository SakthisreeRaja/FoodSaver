import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: _buildManagementList(
        items: List.generate(10, (index) => 'User ${index + 1}'),
        onEdit: (item) {},
        onDelete: (item) {},
      ),
    );
  }
}

class ManageNgosScreen extends StatelessWidget {
  const ManageNgosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage NGOs'),
      ),
      body: _buildManagementList(
        items: List.generate(5, (index) => 'NGO ${index + 1}'),
        onEdit: (item) {},
        onDelete: (item) {},
      ),
    );
  }
}

class ManageVolunteersScreen extends StatelessWidget {
  const ManageVolunteersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Volunteers'),
      ),
      body: _buildManagementList(
        items: List.generate(8, (index) => 'Volunteer ${index + 1}'),
        onEdit: (item) {},
        onDelete: (item) {},
      ),
    );
  }
}

class ManageDonationsScreen extends StatelessWidget {
  const ManageDonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Donations'),
      ),
      body: _buildManagementList(
        items: List.generate(15, (index) => 'Donation ${index + 1}'),
        onEdit: (item) {},
        onDelete: (item) {},
      ),
    );
  }
}


Widget _buildManagementList({
  required List<String> items,
  required Function(String) onEdit,
  required Function(String) onDelete,
}) {
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return ListTile(
        title: Text(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => onEdit(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(item),
            ),
          ],
        ),
      );
    },
  );
}
