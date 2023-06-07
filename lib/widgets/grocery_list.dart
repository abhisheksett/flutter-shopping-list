import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_shopping_list/data/categories.dart';
import 'package:flutter_shopping_list/models/grocery_item.dart';
import 'package:flutter_shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _groceryItems = [];
  var _isLoading = true;
  String? _error;

  void _loadItems() async {
    try {
      final url = Uri.https(dotenv.env['FIREBASE_URL']!, 'shopping-list.json');
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try later';
        });
      }

      if (response.body == 'null') {
        // firebase returns string null in case of no data
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((categoryItem) =>
                categoryItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try later';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (context) => const NewItem()),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _onTap(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    final updatedItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (context) => NewItem(item: item)),
    );

    if (updatedItem == null) {
      return;
    }

    setState(() {
      _groceryItems.remove(item);
      _groceryItems.insert(index, updatedItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url =
        Uri.https(dotenv.env['FIREBASE_URL']!, 'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      _groceryItems.insert(index, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No item added yet'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (ctx, index) {
            final GroceryItem item = _groceryItems[index];
            return Dismissible(
              key: ValueKey(item.id),
              onDismissed: (direction) {
                _removeItem(item);
              },
              child: ListTile(
                title: Text(item.name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: item.category.color,
                ),
                trailing: Text(item.quantity.toString()),
                onTap: () => _onTap(item),
              ),
            );
          });
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }
}
