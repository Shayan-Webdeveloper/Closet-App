    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';
    import 'package:image_picker/image_picker.dart';

    import '../services/background_remover.dart';

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
      String _modelStatus = 'Loading model...';
      bool _isProcessing = false;

      @override
      void dispose() {
        _nameController.dispose();
        _categoryController.dispose();
        _colorController.dispose();
        _remover.dispose();
        super.dispose();
      }

      void _saveItem() {
        if (_imageBytes == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please select an image')));
          return;
        }
        if (_nameController.text.trim().isEmpty ||
            _categoryController.text.trim().isEmpty ||
            _colorController.text.trim().isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
          return;
        }
        debugPrint(
          'Item: ${_nameController.text.trim()}, '
          '${_categoryController.text.trim()}, ${_colorController.text.trim()}',
        );
        debugPrint('PNG bytes: ${_imageBytes?.length}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item validated! Ready for upload.')),
        );
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
          debugPrint('Background removal took ${stopwatch.elapsed.inSeconds}s');

          if (!mounted) return;
          setState(() {
            _imageBytes = cutout;
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
