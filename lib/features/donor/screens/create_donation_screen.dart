import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/components/primary_button.dart';

class CreateDonationScreen extends StatefulWidget {
  const CreateDonationScreen({super.key});

  @override
  State<CreateDonationScreen> createState() => _CreateDonationScreenState();
}

class _CreateDonationScreenState extends State<CreateDonationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text("Take a photo"),
                onTap: () async {
                  Navigator.pop(context);
                  final imagePath = await context.push<String>('/camera');
                  if (imagePath != null && mounted) {
                    setState(() => _pickedImage = XFile(imagePath));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text("Choose from gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Donation"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let AI analyze your food",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Take a clear picture of the food you wish to donate. Our AI will automatically categorize it and check for spoilage.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Camera / Upload Area
            Expanded(
              child: GestureDetector(
                onTap: _isPicking ? null : _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _pickedImage != null
                        ? DecorationImage(
                            image: FileImage(File(_pickedImage!.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isPicking
                                ? const CircularProgressIndicator()
                                : Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text("Tap to open camera", style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text("or select from gallery", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            PrimaryButton(
              text: "Analyze Image",
              enabled: _pickedImage != null,
              onPressed: () => context.push('/analyze', extra: _pickedImage!.path),
            ),
          ],
        ),
      ),
    );
  }
}
