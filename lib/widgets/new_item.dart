import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_shopping_list/data/categories.dart';
import 'package:flutter_shopping_list/models/category.dart';
import 'package:flutter_shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  final GroceryItem? item;
  const NewItem({super.key, this.item});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  var _id = '';
  var _enteredName = '';
  var _enteredQuantity = 0;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      // setState(() {
      _id = item.id;
      _enteredName = item.name;
      _enteredQuantity = item.quantity;
      _selectedCategory = item.category;
      // });
    }
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });

      late final responseData;
      // if id exists, its put. Else post
      if (_id != '') {
        final url =
            Uri.https(dotenv.env['FIREBASE_URL']!, 'shopping-list/$_id.json');
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(
            {
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'category': _selectedCategory.title,
            },
          ),
        );
        print(response.body);
        responseData = json.decode(response.body);
      } else {
        final url =
            Uri.https(dotenv.env['FIREBASE_URL']!, 'shopping-list.json');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(
            {
              'name': _enteredName,
              'quantity': _enteredQuantity,
              'category': _selectedCategory.title,
            },
          ),
        );
        print(response.body);
        responseData = json.decode(response.body);
      }

      if (!context.mounted) {
        // if widget is not part of the screen anymore, then return
        return;
      }
      Navigator.of(context).pop(
        GroceryItem(
          id: _id != '' ? _id : responseData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _selectedCategory,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _id != '' ? const Text('Update item') : const Text('Add new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                initialValue: _enteredName != '' ? _enteredName : '',
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1 or 50 charaters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: _enteredQuantity != 0
                          ? _enteredQuantity.toString()
                          : '1',
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title)
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: _isSending
                          ? null
                          : () {
                              _formKey.currentState!.reset();
                            },
                      child: const Text('Reset')),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : _id != ''
                            ? const Text('Update Item')
                            : const Text('Add Item'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
