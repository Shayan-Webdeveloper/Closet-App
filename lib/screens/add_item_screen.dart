    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
    import '../services/background_remover.dart';
import 'package:image/image.dart' as img;
    class AddItemScreen extends StatefulWidget {
      const AddItemScreen({super.key});

      @override
      State<AddItemScreen> createState() => _AddItemScreenState();
    }

    class _AddItemScreenState extends State<AddItemScreen> {
      final ImagePicker _picker = ImagePicker();
      final BackgroundRemover _remover = BackgroundRemover();
      final TextEditingController _nameController = TextEditingController();
      final TextEditingController _categoryController = TextEditingController();
      final TextEditingController _colorController = TextEditingController();

      Uint8List? _imageBytes; // transparent PNG after processing
      // String _modelStatus = 'Loading model...';
      bool _isProcessing = false;

      @override
      void dispose() {
        _nameController.dispose();
        _categoryController.dispose();
        _colorController.dispose();
        _remover.dispose();
        super.dispose();
      }

      
Uint8List cropTransparentEdges(Uint8List pngBytes) {
  final decoded = img.decodeImage(pngBytes);

  if (decoded == null) return pngBytes;

  final cropped = img.trim(
    decoded,
    mode: img.TrimMode.transparent,
  );

  return Uint8List.fromList(img.encodePng(cropped));
}

Future<void> _saveItem() async {
  if (_isProcessing) return;

  if (_imageBytes == null) {
   ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select an image')),
    ); 
    return;
  }

  final name = _nameController.text.trim();
  final category = _categoryController.text.trim();
  final color = _colorController.text.trim();

  if (name.isEmpty || category.isEmpty || color.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  setState(() => _isProcessing = true);

  try {
    final supabase = Supabase.instance.client;

    final filePath =
        '${DateTime.now().millisecondsSinceEpoch}.png';

    await supabase.storage
        .from('cutouts')
        .uploadBinary(
          filePath,
          _imageBytes!,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );

    await supabase.from('items').insert({
      'name': name,
      'category': category,
      'color': color,
      'image_path': filePath,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item saved successfully!')),
    );

    setState(() {
      _imageBytes = null;
      _nameController.clear();
      _categoryController.clear();
      _colorController.clear();
    });
  } catch (e) {
    debugPrint('SAVE ITEM ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save item: $e')),
    );
  } finally {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}

      Future<void> _pickImage(ImageSource source) async {
        try {
          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 1024,
            maxHeight: 1024,
          );
          if (!mounted || image == null) return;

          final bytes = await image.readAsBytes();
          if (!mounted) return;

          setState(() {
            _isProcessing = true;
            _imageBytes = null;
          });

          final stopwatch = Stopwatch()..start();
          final cutout = await _remover.removeBackground(bytes);
final croppedCutout = cropTransparentEdges(cutout);
          debugPrint('Background removal took ${stopwatch.elapsed.inSeconds}s');

          if (!mounted) return;
          setState(() {
            _imageBytes = croppedCutout;
            _isProcessing = false;
          });
        } catch (e) {
          debugPrint('IMAGE ERROR: $e');
          if (!mounted) return;
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Add an Item')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  child: const Text('Take Photo'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  child: const Text('Choose from Gallery'),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: _isProcessing
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Removing background...'),
                          ],
                        )
                      : _imageBytes == null
                      ? const Text('No image selected')
                      : Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g. Shirt, Jeans, Jacket',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _colorController,
                  decoration: const InputDecoration(
                    labelText: 'Color',
                    hintText: 'e.g. Black, Blue, White',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _saveItem,
                  child: const Text('Save Item'),
                ),
              ],
            ),
          ),
        );
      }
    }
