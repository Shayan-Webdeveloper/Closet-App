import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

const int _size = 320;
const int _maxOutputSize = 1024;

class BackgroundRemover {
  OrtSession? _session;

  Future<void> _ensureSession() async {
    _session ??= await OnnxRuntime().createSessionFromAsset(
      'assets/models/u2netp.onnx',
      options: OrtSessionOptions(
        intraOpNumThreads: 1,
        interOpNumThreads: 1,
        useArena: false,
      ),
    );
  }

  /// Takes the original photo bytes and returns a transparent PNG.
  Future<Uint8List> removeBackground(Uint8List imageBytes) async {
    final Float32List input = await compute(_preprocess, imageBytes);
    await _ensureSession();
    final inputTensor = await OrtValue.fromList(input, [1, 3, _size, _size]);
    late final Float32List mask;
    Map<String, OrtValue>? outputs;

    try {
      if (_session!.outputNames.isEmpty) {
        throw StateError('Background removal model has no output tensors');
      }
      outputs = await _session!.run({'input.1': inputTensor});
      final outTensor = outputs[_session!.outputNames.first];
      if (outTensor == null) {
        throw StateError('Background removal model returned no output');
      }

      final raw = await outTensor.asFlattenedList();
      if (raw.length != _size * _size) {
        throw StateError(
          'Background removal model returned an unexpected mask size: '
          '${raw.length}',
        );
      }

      mask = Float32List(raw.length);
      var minValue = double.infinity;
      var maxValue = -double.infinity;
      for (int i = 0; i < raw.length; i++) {
        final value = (raw[i] as num).toDouble();
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
      final range = maxValue - minValue;
      if (range > 0) {
        for (int i = 0; i < raw.length; i++) {
          mask[i] = ((raw[i] as num).toDouble() - minValue) / range;
        }
      }
    } finally {
      for (final output in outputs?.values ?? const <OrtValue>[]) {
        await output.dispose();
      }
      await inputTensor.dispose();
    }

    return compute(_applyMask, {'image': imageBytes, 'mask': mask});
  }

  Future<void> dispose() async {
    await _session?.close();
    _session = null;
  }
}

Float32List _preprocess(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode the selected image');
  }
  final oriented = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    oriented,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.linear,
  );

  const mean = [0.485, 0.456, 0.406];
  const std = [0.229, 0.224, 0.225];
  const plane = _size * _size;
  final out = Float32List(3 * plane);

  for (int y = 0; y < _size; y++) {
    for (int x = 0; x < _size; x++) {
      final pixel = resized.getPixel(x, y);
      final i = y * _size + x;
      out[i] = (pixel.r / 255.0 - mean[0]) / std[0];
      out[plane + i] = (pixel.g / 255.0 - mean[1]) / std[1];
      out[2 * plane + i] = (pixel.b / 255.0 - mean[2]) / std[2];
    }
  }
  return out;
}

Uint8List _applyMask(Map<String, dynamic> args) {
  final Uint8List bytes = args['image'];
  final Float32List mask = args['mask'];

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode the selected image');
  }
  var image = img.bakeOrientation(decoded);

  if (image.width > _maxOutputSize || image.height > _maxOutputSize) {
    image = image.width >= image.height
        ? img.copyResize(image, width: _maxOutputSize)
        : img.copyResize(image, height: _maxOutputSize);
  }

  final width = image.width;
  final height = image.height;
  final output = img.Image(width: width, height: height, numChannels: 4);

  for (int y = 0; y < height; y++) {
    final maskY = (y * _size ~/ height).clamp(0, _size - 1);
    for (int x = 0; x < width; x++) {
      final maskX = (x * _size ~/ width).clamp(0, _size - 1);
      final alpha = (mask[maskY * _size + maskX] * 255).round().clamp(0, 255);
      final pixel = image.getPixel(x, y);
      output.setPixelRgba(
        x,
        y,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
        alpha,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(output));
}
