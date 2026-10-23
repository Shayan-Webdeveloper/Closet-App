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

  List<Map<String, dynamic>> _items = [];
  final Set<String> _selectedItemIds = {};
  final TextEditingController _lookNameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final supabase = Supabase.instance.client;

    final data = await supabase
        .from('items')
        .select('id, name, category, color, image_path');

    final items = <Map<String, dynamic>>[];

    for (final item in data) {
      final imageUrl = await supabase.storage
          .from('cutouts')
          .createSignedUrl(item['image_path'], 3600);

      items.add({...item, 'image_url': imageUrl});
    }

    if (!mounted) return;

    setState(() {
      _items = items;
    });
  }

  Future<void> _saveLook() async {
    final supabase = Supabase.instance.client;

    final look = await supabase
        .from('looks')
        .insert({'name': _lookNameController.text.trim()})
        .select('id')
        .single();

    final lookId = look['id'];

    final lookItems = _selectedItemIds.map((itemId) {
      return {'look_id': lookId, 'item_id': itemId};
    }).toList();

    await supabase.from('look_items').insert(lookItems);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Look saved successfully!')));

    setState(() {
      _lookNameController.clear();
      _selectedItemIds.clear();
    });
  }

  Widget _buildLookPreviewContent() {
    final selectedItems = _items.where((item) {
      return _selectedItemIds.contains(item['id']);
    }).toList();

    int getOrder(Map<String, dynamic> item) {
      final category = item['category'].toString().trim().toLowerCase();

      if (category.contains('shirt') ||
          category.contains('t-shirt') ||
          category.contains('tshirt') ||
          category.contains('top') ||
          category.contains('jacket') ||
          category.contains('hoodie') ||
          category.contains('sweater') ||
          category.contains('blouse')) {
        return 0;
      }

      if (category.contains('pant') ||
          category.contains('jean') ||
          category.contains('trouser') ||
          category.contains('skirt') ||
          category.contains('short')) {
        return 1;
      }

      if (category.contains('shoe') ||
          category.contains('sneaker') ||
          category.contains('boot') ||
          category.contains('sandal')) {
        return 2;
      }

      return 3;
    }

    selectedItems.sort((a, b) => getOrder(a).compareTo(getOrder(b)));

    if (selectedItems.isEmpty) {
      return const Center(child: Text('Select items to preview your look'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWeight = selectedItems.fold<int>(0, (total, item) {
          final order = getOrder(item);

          if (order == 0) return total + 35;
          if (order == 1) return total + 45;
          if (order == 2) return total + 12;
          return total + 20;
        });

        return Column(
          children: selectedItems.map((item) {
            final order = getOrder(item);

            final weight = order == 0
                ? 35
                : order == 1
                ? 45
                : order == 2
                ? 12
                : 20;

            return SizedBox(
              width: double.infinity,
              height: constraints.maxHeight * weight / totalWeight,
              child: Align(
                alignment: Alignment.center,
                // child: Transform.translate(
                  // offset: Offset(order == 1 ? constraints.maxWidth * 0 : 0, 0),
                  child: Image.network(
                    item['image_url'],
                    fit: BoxFit.contain,
                    width: constraints.maxWidth * 0.65,
                  ),
                // ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create a Look')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _lookNameController,
              decoration: const InputDecoration(
                labelText: 'Look Name',
                hintText: 'e.g. Casual Outfit',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Select clothing items
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];

                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                secondary: SizedBox(
                                  width: 45,
                                  height: 55,
                                  child: Image.network(
                                    item['image_url'],
                                    fit: BoxFit.contain,
                                  ),
                                ),
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
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // RIGHT COLUMN: Outfit preview
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Outfit Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints.expand(),
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: _buildLookPreviewContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveLook,
                child: const Text('Save Look'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
