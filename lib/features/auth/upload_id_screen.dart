import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import 'auth_provider.dart';

class UploadIdScreen extends ConsumerStatefulWidget {
  const UploadIdScreen({super.key});

  @override
  ConsumerState<UploadIdScreen> createState() => _UploadIdScreenState();
}

class _UploadIdScreenState extends ConsumerState<UploadIdScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    // Simulate upload or call repository (would need to add this method to repo)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আইডি কার্ড সফলভাবে আপলোড হয়েছে'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('আইডি কার্ড আপলোড'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.space24),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.space32),
            const Text(
              'আপনার বিশ্ববিদ্যালয়ের পরিচয়পত্র আপলোড করুন',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.space32),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge - 2,
                        ),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 64,
                            color: AppTheme.primaryBlue.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ছবি সিলেক্ট করুন',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedImage == null || _isUploading
                  ? null
                  : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.all(AppTheme.space16),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'আপলোড সম্পন্ন করুন',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: AppTheme.space48),
          ],
        ),
      ),
    );
  }
}
