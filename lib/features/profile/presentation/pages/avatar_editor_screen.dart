import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({
    required this.imageFile,
    super.key,
  });

  final File imageFile;

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3 quarter turns (0, 90, 180, 270 deg)
  bool _flipHorizontal = false;
  bool _processing = false;

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _toggleFlip() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _reset() {
    setState(() {
      _rotationQuarterTurns = 0;
      _flipHorizontal = false;
    });
  }

  Future<void> _applyAndFinalize() async {
    setState(() => _processing = true);
    try {
      final bytes = await widget.imageFile.readAsBytes();
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        if (mounted) Navigator.pop(context, widget.imageFile);
        return;
      }

      // Apply rotation if needed
      if (_rotationQuarterTurns != 0) {
        final degrees = _rotationQuarterTurns * 90;
        decoded = img.copyRotate(decoded, angle: degrees);
      }

      // Apply horizontal flip if needed
      if (_flipHorizontal) {
        decoded = img.flipHorizontal(decoded);
      }

      // Crop to square center so it fits cleanly in a CircleAvatar
      final size = decoded.width < decoded.height ? decoded.width : decoded.height;
      final x = (decoded.width - size) ~/ 2;
      final y = (decoded.height - size) ~/ 2;
      final cropped = img.copyCrop(decoded, x: x, y: y, width: size, height: size);

      // Encode as JPEG
      final encoded = img.encodeJpg(cropped, quality: 90);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/avatar_edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(tempPath);
      await outFile.writeAsBytes(encoded);

      if (mounted) {
        Navigator.pop(context, outFile);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context, widget.imageFile);
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: _processing ? null : () => Navigator.pop(context, null),
        ),
        title: const Text(
          'Edit Profile Picture',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _processing ? null : _applyAndFinalize,
            child: _processing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),

          // Circular Preview Area
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scaleX: _flipHorizontal ? -1.0 : 1.0,
                      child: RotatedBox(
                        quarterTurns: _rotationQuarterTurns,
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.cover,
                          width: 280,
                          height: 280,
                        ),
                      ),
                    ),
                  ),
                ),
                // Overlay ring to show circular crop boundaries
                IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Adjust rotation or flip before saving',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),

          const Spacer(),

          // Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToolButton(
                    icon: Icons.rotate_left_rounded,
                    label: 'Rotate Left',
                    onTap: _processing ? null : _rotateLeft,
                  ),
                  _buildToolButton(
                    icon: Icons.rotate_right_rounded,
                    label: 'Rotate Right',
                    onTap: _processing ? null : _rotateRight,
                  ),
                  _buildToolButton(
                    icon: Icons.flip_rounded,
                    label: 'Flip',
                    onTap: _processing ? null : _toggleFlip,
                  ),
                  _buildToolButton(
                    icon: Icons.refresh_rounded,
                    label: 'Reset',
                    onTap: _processing ? null : _reset,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
