import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EnhancedImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<List<String>?> pickMultipleImages({
    required BuildContext context,
    bool enableCrop = true,
    int quality = 85,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 100,
      );
      if (images.isEmpty) return null;

      final List<String> processedPaths = [];

      for (final image in images) {
        String? processedPath = await _processImage(
          context: context,
          imagePath: image.path,
          enableCrop: enableCrop,
          quality: quality,
        );

        if (processedPath != null) {
          processedPaths.add(processedPath);
        }
      }

      return processedPaths.isEmpty ? null : processedPaths;
    } catch (e) {
      print('Error picking multiple images: $e');
      return null;
    }
  }

  static Future<String?> pickSingleImage({
    required BuildContext context,
    ImageSource source = ImageSource.gallery,
    bool enableCrop = true,
    int quality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return null;

      return await _processImage(
        context: context,
        imagePath: image.path,
        enableCrop: enableCrop,
        quality: quality,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<String?> _processImage({
    required BuildContext context,
    required String imagePath,
    required bool enableCrop,
    required int quality,
  }) async {
    try {
      String processedPath = imagePath;

      // Show processing options dialog
      if (!context.mounted) return null;
      
      final shouldProcess = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ImageProcessingDialog(
          imagePath: imagePath,
          defaultQuality: quality,
        ),
      );

      if (shouldProcess == null) return null;

      final bool doCrop = shouldProcess['crop'] ?? false;
      final int selectedQuality = shouldProcess['quality'] ?? quality;

      // Crop if enabled
      if (enableCrop && doCrop) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: processedPath,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: const Color(0xFF2DBD6C),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioPresets: [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
          ],
        );

        if (croppedFile != null) {
          processedPath = croppedFile.path;
        }
      }

      // Compress image
      final compressedPath = await _compressImage(processedPath, selectedQuality);
      return compressedPath ?? processedPath;
    } catch (e) {
      print('Error processing image: $e');
      return imagePath;
    }
  }

  static Future<String?> _compressImage(String imagePath, int quality) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final targetPath = path.join(
        dir.path,
        'nova_images',
        'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create directory if it doesn't exist
      await Directory(path.dirname(targetPath)).create(recursive: true);

      final result = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      return result?.path;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
}

class _ImageProcessingDialog extends StatefulWidget {
  final String imagePath;
  final int defaultQuality;

  const _ImageProcessingDialog({
    required this.imagePath,
    required this.defaultQuality,
  });

  @override
  State<_ImageProcessingDialog> createState() => _ImageProcessingDialogState();
}

class _ImageProcessingDialogState extends State<_ImageProcessingDialog> {
  late int _quality;
  bool _enableCrop = false;

  @override
  void initState() {
    super.initState();
    _quality = widget.defaultQuality;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: const Text('Image Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.imagePath),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // Crop option
          SwitchListTile(
            title: const Text('Crop Image'),
            subtitle: const Text('Adjust the image size and aspect ratio'),
            value: _enableCrop,
            onChanged: (value) {
              setState(() => _enableCrop = value);
            },
            activeThumbColor: const Color(0xFF2DBD6C),
          ),

          const SizedBox(height: 16),

          // Quality slider
          Text(
            'Image Quality: $_quality%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _quality.toDouble(),
            min: 50,
            max: 100,
            divisions: 10,
            label: '$_quality%',
            activeColor: const Color(0xFF2DBD6C),
            onChanged: (value) {
              setState(() => _quality = value.toInt());
            },
          ),
          Text(
            'Higher quality = larger file size',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'crop': _enableCrop,
              'quality': _quality,
            });
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2DBD6C),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
