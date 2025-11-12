// lib/dashboard.dart

import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dbhelper.dart'; // Your DbHelper

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = "";
  final dbHelper = DbHelper.instance;
  final ImagePicker _picker = ImagePicker(); // Add ImagePicker instance

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => name = prefs.getString('name') ?? "User");
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  Future<void> _loadItems() async {
    final data = await dbHelper.queryAllContacts();
    setState(() {
      _items = data;
      _filteredItems = data;
    });
  }

  void _searchItems(String query) {
    final lowerCaseQuery = query.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        final company = item[DbHelper.columnCName].toString().toLowerCase();
        final product = item[DbHelper.columnPName].toString().toLowerCase();
        return company.contains(lowerCaseQuery) ||
            product.contains(lowerCaseQuery);
      }).toList();
    });
  }

  Future<void> _deleteItem(int id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmDelete == true) {
      await dbHelper.deleteContact(id);
      _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Welcome, $name'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchItems,
              decoration: InputDecoration(
                hintText: 'Search by Company or Product...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filteredItems.isEmpty
          ? Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No products yet. Add one!'
              : 'No products found.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildProductCard(item);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditItem(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- UPDATED WIDGETS ---

  Widget _buildProductCard(Map<String, dynamic> item) {
    // Safely get the image bytes
    final imageBytes = item[DbHelper.columnImage] as Uint8List?;
    final price = item[DbHelper.columnPrice] as double? ?? 0.0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[300],
          // Display the image if it exists, otherwise show an icon
          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,

        ),
        title: Text(
          item[DbHelper.columnCName] ,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            "${item[DbHelper.columnPName]  }\nType: ${item[DbHelper
                .columnType] }"),
        // Display the price in the trailing section
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _addOrEditItem(existingItem: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItem(item[DbHelper.columnId1]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addOrEditItem({Map<String, dynamic>? existingItem}) async {
    final companyController = TextEditingController(
        text: existingItem?[DbHelper.columnCName] ?? '');
    final productController = TextEditingController(
        text: existingItem?[DbHelper.columnPName] ?? '');
    final typeController = TextEditingController(
        text: existingItem?[DbHelper.columnType] ?? '');
    // Add controller for price
    final priceController = TextEditingController(
        text: existingItem?[DbHelper.columnPrice]?.toString() ?? '');
    // Variable to hold the image bytes
     var imageBytes = existingItem?[DbHelper.columnImage];

    Future<void> onSave() async {
      final company = companyController.text.trim();
      final product = productController.text.trim();
      final type = typeController.text.trim();
      // Parse the price
      final price = double.tryParse(priceController.text);

      if (company.isEmpty || product.isEmpty || type.isEmpty || price == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill all fields correctly.')),
          );
        }
        return;
      }

      final itemData = {
        DbHelper.columnCName: company,
        DbHelper.columnPName: product,
        DbHelper.columnType: type,
        DbHelper.columnPrice: price, // Add price
        DbHelper.columnImage: imageBytes, // Add image
      };

      if (existingItem == null) {
        await dbHelper.insertContact(itemData);
      } else {
        itemData[DbHelper.columnId1] = existingItem[DbHelper.columnId1];
        await dbHelper.updateContact(itemData);
      }

      if (mounted) Navigator.of(context).pop();
      _loadItems();
    }

    await showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder( // Use StatefulBuilder to update dialog state
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text(
                    existingItem == null ? 'Add Product' : 'Edit Product'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- IMAGE PICKER UI ---
                      GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile = await _picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            final bytes = await pickedFile.readAsBytes();
                            setStateDialog(() {
                              imageBytes = bytes; // Update the image preview
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: imageBytes != null ? MemoryImage(
                              imageBytes!) : null,
                          child: imageBytes == null
                              ? const Icon(Icons.camera_alt, color: Colors.grey,
                              size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: companyController,
                          decoration: const InputDecoration(
                              labelText: 'Company Name')),
                      TextField(controller: productController,
                          decoration: const InputDecoration(
                              labelText: 'Product Name')),
                      TextField(controller: typeController,
                          decoration: const InputDecoration(
                              labelText: 'Type (e.g., Mobile)')),
                      // --- PRICE INPUT FIELD ---
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(
                            labelText: 'Price', prefixText: '₹'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel')),
                  ElevatedButton(onPressed: onSave,
                      child: Text(existingItem == null ? 'Add' : 'Update')),
                ],
              );
            },
          ),
    );
  }
}