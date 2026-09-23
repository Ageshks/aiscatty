import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/media_upload_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/kerala_districts.dart';

/// Edit an existing pet listing. Only the owner can reach this page (opened
/// from My Listings). Media is uploaded to the existing Cloudinary preset and
/// removed files are handled so no orphaned references remain.
class PetEditPage extends StatefulWidget {
  const PetEditPage({super.key, required this.petId, required this.petData});
  final String petId;
  final Map<String, dynamic> petData;

  @override
  State<PetEditPage> createState() => _PetEditPageState();
}

class _PetEditPageState extends State<PetEditPage> {
  late final TextEditingController nameController;
  late final TextEditingController breedController;
  late final TextEditingController descriptionController;
  late final TextEditingController locationController;

  String? age;
  String? gender;
  String? species;
  String status = 'available';
  String district = '';
  String state = 'Kerala';

  File? newMediaFile;
  String? newStatusVideoPath; // local path of a replacement video
  String? existingMediaUrl;
  String? existingVideoUrl;
  final picker = ImagePicker();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.petData;
    nameController = TextEditingController(text: d['name']?.toString() ?? '');
    breedController = TextEditingController(text: d['breed']?.toString() ?? '');
    descriptionController = TextEditingController(text: d['description']?.toString() ?? '');
    locationController = TextEditingController(text: d['location']?.toString() ?? '');
    age = d['age']?.toString();
    gender = d['gender']?.toString();
    species = d['species']?.toString() ?? 'Dog';
    status = d['status']?.toString() ?? 'available';
    district = d['district']?.toString() ?? '';
    state = d['state']?.toString() ?? 'Kerala';
    existingMediaUrl = d['mediaUrl']?.toString();
    existingVideoUrl = d['statusVideoUrl']?.toString();
  }

  Future<String?> _upload(File file) => MediaUploadService.uploadFile(file);

  /// Best-effort cleanup note: the unsigned Cloudinary preset does not allow
  /// client-side deletion without an API secret; deletion should be done via
  /// a secured server endpoint. Kept as a documented non-fatal hook.
  Future<void> _deleteRemoteMedia(String url) async {}

  Future<void> _pickReplacementVideo({required bool fromCamera}) async {
    final picked = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null) return;
    final file = File(picked.path);
    final error = await MediaUploadService.validateVideo(file);
    if (error != null) {
      Get.snackbar('Video not allowed', error);
      return;
    }
    setState(() => newStatusVideoPath = picked.path);
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Missing info', 'Pet name is required');
      return;
    }
    setState(() => saving = true);
    try {
      final petRef = FirebaseFirestore.instance.collection('pets').doc(widget.petId);

      String? mediaUrl = existingMediaUrl;
      if (newMediaFile != null) {
        final uploaded = await _upload(newMediaFile!);
        if (uploaded == null) throw StateError('Photo upload failed');
        if (mediaUrl != null) await _deleteRemoteMedia(mediaUrl);
        mediaUrl = uploaded;
      }

      String? videoUrl = existingVideoUrl;
      if (newStatusVideoPath != null) {
        final uploaded = await _upload(File(newStatusVideoPath!));
        if (uploaded == null) throw StateError('Video upload failed');
        if (videoUrl != null) await _deleteRemoteMedia(videoUrl);
        videoUrl = uploaded;
      }

      await petRef.update({
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'age': age,
        'gender': gender,
        'species': species,
        'status': status,
        'district': district,
        'state': state,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        // Removing the video clears the field in Firestore too.
        'statusVideoUrl': videoUrl ?? FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Get.back();
      Get.snackbar('Saved 🐾', 'Listing updated successfully');
    } catch (e) {
      Get.snackbar('Could not save', e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _pickDistrict() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select district 📍',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final name in KeralaDistricts.names)
              ListTile(
                title: Text(name),
                trailing: name == district ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () => Navigator.pop(context, name),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => district = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        title: const Text('Edit Pet ✏️'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(child: Column(children: [
              _input(nameController, 'Pet Name'),
              const SizedBox(height: 10),
              _input(breedController, 'Breed'),
              const SizedBox(height: 10),
              _input(descriptionController, 'Description', maxLines: 3),
            ])),
            _card(child: Column(children: [
              DropdownButtonFormField(
                value: species,
                items: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => species = v),
                decoration: const InputDecoration(labelText: 'Species'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: age,
                items: ['Puppy', 'Young', 'Adult']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => age = v),
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: gender,
                items: ['Male', 'Female']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => gender = v),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'available', child: Text('Available for Adoption')),
                  DropdownMenuItem(value: 'pending', child: Text('Adoption Pending')),
                  DropdownMenuItem(value: 'adopted', child: Text('Adopted ❤️')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'available'),
                decoration: const InputDecoration(labelText: 'Adoption status'),
              ),
            ])),
            _card(child: Column(children: [
              _input(locationController, 'Location (e.g. Kunnamkulam)'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      district.isEmpty ? 'No district selected' : 'District: $district • $state',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(onPressed: _pickDistrict, child: const Text('Change')),
                ],
              ),
            ])),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Photos 📸', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (existingMediaUrl != null && newMediaFile == null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(existingMediaUrl!, width: 70, height: 70, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 70, height: 70)),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) setState(() => newMediaFile = File(picked.path));
                    },
                    child: const Text('Replace photo'),
                  ),
                ],
              ),
            ])),
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Status video 🎥', style: TextStyle(fontWeight: FontWeight.w600)),
              const Text('Up to 30 seconds • max 50 MB',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (existingVideoUrl != null && newStatusVideoPath == null)
                    const Chip(label: Text('Video uploaded 🎥')),
                  ElevatedButton.icon(
                    onPressed: () => _pickReplacementVideo(fromCamera: true),
                    icon: const Icon(Icons.videocam),
                    label: const Text('Record'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickReplacementVideo(fromCamera: false),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                  if (existingVideoUrl != null || newStatusVideoPath != null)
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        newStatusVideoPath = null;
                        existingVideoUrl = null; // removed on save
                      }),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove video'),
                    ),
                ],
              ),
            ])),
            const SizedBox(height: 12),
            saving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Save Changes'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _input(TextEditingController controller, String label, {int maxLines = 1}) => TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
