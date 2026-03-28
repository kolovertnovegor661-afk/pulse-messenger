import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _loading = false;
  File? _avatar;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserDataProvider).value;
    if (user != null) {
      _nameCtrl.text = user.displayName;
      _userCtrl.text = user.username;
      _bioCtrl.text = user.bio ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? avatarUrl;
    if (_avatar != null) {
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      await ref.putFile(_avatar!);
      avatarUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': _nameCtrl.text.trim(),
      'username': _userCtrl.text.trim().toLowerCase(),
      'bio': _bioCtrl.text.trim(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDataProvider).value;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          GestureDetector(
            onTap: () async {
              final file = await ImagePicker().pickImage(
                  source: ImageSource.gallery, imageQuality: 80);
              if (file != null) setState(() => _avatar = File(file.path));
            },
            child: Stack(children: [
              CircleAvatar(
                radius: 52, backgroundColor: AppColors.surfaceElevated,
                backgroundImage: _avatar != null
                    ? FileImage(_avatar!) as ImageProvider
                    : (user?.avatarUrl != null
                        ? CachedNetworkImageProvider(user!.avatarUrl!)
                        : null),
                child: (_avatar == null && user?.avatarUrl == null)
                    ? Text(user?.displayName.isNotEmpty == true
                        ? user!.displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.textPrimary,
                            fontSize: 36, fontWeight: FontWeight.w700))
                    : null,
              ),
              Positioned(bottom: 0, right: 0,
                child: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2)),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('Tap to change avatar',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          const SizedBox(height: 32),
          _field(_nameCtrl, 'Display Name', 'Your name', Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _field(_userCtrl, 'Username', 'username', Icons.alternate_email_rounded),
          const SizedBox(height: 16),
          _field(_bioCtrl, 'Bio', 'Write something...', Icons.info_outline_rounded, maxLines: 4),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint,
      IconData icon, {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: AppColors.textSecondary,
          fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20)),
      ),
    ]);
  }
}
