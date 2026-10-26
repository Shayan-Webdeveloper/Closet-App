
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class MyLooksScreen extends StatefulWidget {
  const MyLooksScreen({super.key});

  @override
  State<MyLooksScreen> createState() => _MyLooksScreenState();
}

class _MyLooksScreenState extends State<MyLooksScreen> {
  List<Map<String, dynamic>> _looks = [];

  @override
  void initState() {
    super.initState();
    _fetchLooks();
  }

  Future<void> _fetchLooks() async {
  final supabase = Supabase.instance.client;

  final data = await supabase
      .from('looks')
      .select('id, name, created_at')
      .order('created_at', ascending: false);

  final looks = <Map<String, dynamic>>[];

  for (final look in data) {
    final links = await supabase
        .from('look_items')
        .select('item_id')
        .eq('look_id', look['id']);
        debugPrint('Look: ${look['name']}');
debugPrint('Look ID: ${look['id']}');
debugPrint('Linked items: $links');

    final clothingItems = <Map<String, dynamic>>[];

    for (final link in links) {
      final item = await supabase
          .from('items')
          .select('id, name, category, image_path')
          .eq('id', link['item_id'])
          .single();

      final imageUrl = await supabase.storage
          .from('cutouts')
          .createSignedUrl(item['image_path'], 3600);

      clothingItems.add({
        ...item,
        'image_url': imageUrl,
      });
    }

    looks.add({
      ...look,
      'items': clothingItems,
    });
  }

  if (!mounted) return;

  setState(() {
    _looks = looks;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Looks'),
      ),
      body: ListView.builder(
        itemCount: _looks.length,
        itemBuilder: (context, index) {
          final look = _looks[index];

          final items = List<Map<String, dynamic>>.from(look['items']);

return Card(
  margin: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          look['name'],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 130,
          child: items.isEmpty
              ? const Center(
                  child: Text('No items in this look'),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 100,
                        child: Image.network(
                          item['image_url'],
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  ),
);
        },
      ),
    );
  }
}
