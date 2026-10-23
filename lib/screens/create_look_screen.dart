import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateLookScreen extends StatefulWidget {
  const CreateLookScreen({super.key});

  @override
  State<CreateLookScreen> createState() => _CreateLookScreenState();
}

class _CreateLookScreenState extends State<CreateLookScreen> {
  @override
void dispose() {
  _lookNameController.dispose();
  super.dispose();
}
  @override
  List<Map<String, dynamic>> _items = [];
  final Set<String> _selectedItemIds = {};
  final TextEditingController _lookNameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final data = await Supabase.instance.client
        .from('items')
        .select('id, name, category, color, image_path');

    setState(() {
      _items = List<Map<String, dynamic>>.from(data);
    });
  }
  
Future<void> _saveLook() async {
  final supabase = Supabase.instance.client;

  final look = await supabase
      .from('looks')
      .insert({
        'name': _lookNameController.text.trim(),
      })
      .select('id')
      .single();

  final lookId = look['id'];

  final lookItems = _selectedItemIds.map((itemId) {
    return {
      'look_id': lookId,
      'item_id': itemId,
    };
  }).toList();

  await supabase.from('look_items').insert(lookItems);

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Look saved successfully!'),
    ),
  );

  setState(() {
    _lookNameController.clear();
    _selectedItemIds.clear();
  });
}


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Look')),

      
body: Column(
  children: [
    Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _lookNameController,
        decoration: const InputDecoration(
          labelText: 'Look Name',
          hintText: 'e.g. Casual Outfit',
          border: OutlineInputBorder(),
        ),
      ),
    ),
    Expanded(
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return CheckboxListTile(
            title: Text(item['name']),
            subtitle: Text(
              '${item['category']} - ${item['color']}',
            ),
            value: _selectedItemIds.contains(item['id']),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  _selectedItemIds.add(item['id']);
                } else {
                  _selectedItemIds.remove(item['id']);
                }
              });
            },
          );
        },
      ),
    ),
  Padding(
  padding: const EdgeInsets.all(16),
  child: ElevatedButton(
    onPressed: _saveLook,
    child: const Text('Save Look'),
  ),
),
  ],
),

    );
  }
}
