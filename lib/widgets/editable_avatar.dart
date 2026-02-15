import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableAvatar extends ConsumerWidget {
  final String? profilePhotoUrl;
  final bool isUploading;
  final VoidCallback onTap;
  final double radius;

  const EditableAvatar({
    super.key,
    required this.profilePhotoUrl,
    required this.onTap,
    this.isUploading = false,
    this.radius = 60,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: profilePhotoUrl != null
                  ? Image.network(
                      profilePhotoUrl!,
                      fit: BoxFit.cover,
                      width: radius * 2,
                      height: radius * 2,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.person,
                            size: radius,
                            color: Colors.teal.shade700,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.person,
                        size: radius,
                        color: Colors.teal.shade700,
                      ),
                    ),
            ),
          ),
          if (isUploading)
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
