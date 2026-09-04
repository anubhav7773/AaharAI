import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/scanner_controller.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_compressor.dart';

class UniversalScannerScreen extends ConsumerStatefulWidget {
  const UniversalScannerScreen({super.key});

  @override
  ConsumerState<UniversalScannerScreen> createState() =>
      _UniversalScannerScreenState();
}

class _UniversalScannerScreenState extends ConsumerState<UniversalScannerScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMode = 0; // 0 = Barcode Scan, 1 = Label OCR Photo
  final MobileScannerController _barcodeController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isFlashOn = false;

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    // Warm up backend on camera open
    ref.read(apiClientProvider).warmUpServer();

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 260.0).animate(
      CurvedAnimation(
        parent: _laserAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _laserAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    setState(() => _isFlashOn = !_isFlashOn);
    try {
      await _barcodeController.toggleTorch();
    } catch (_) {}
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _selectedMode != 0) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);
    final result = await ref
        .read(scannerControllerProvider.notifier)
        .processBarcode(barcode);
    setState(() => _isProcessing = false);

    if (result != null && mounted) {
      context.push('/analysis', extra: result);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AaharTheme.textHeadline,
          content: const Text(
            'Product not in barcode database. Please snap a label photo.',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            label: 'Snap Label',
            textColor: const Color(0xFF22C55E),
            onPressed: () => setState(() => _selectedMode = 1),
          ),
        ),
      );
    }
  }

  Future<void> _captureLabelPhoto() async {
    if (_isProcessing) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (picked == null) return;

      setState(() => _isProcessing = true);
      final compressedFile =
          await ImageCompressor.compressForGemini(File(picked.path));

      final result = await ref
          .read(scannerControllerProvider.notifier)
          .processImage(compressedFile);
      if (result != null && mounted) {
        context.push('/analysis', extra: result);
      } else if (mounted) {
        final err = ref.read(scannerControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AaharTheme.textHeadline,
            content: Text(
              err != null
                  ? 'Analysis error: $err'
                  : 'Could not extract nutrition from this label. Please snap a clearer photo of the nutrition table.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process label: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      final compressed =
          await ImageCompressor.compressForGemini(File(picked.path));
      final result = await ref
          .read(scannerControllerProvider.notifier)
          .processImage(compressed);
      if (result != null && mounted) {
        context.push('/analysis', extra: result);
      } else if (mounted) {
        final err = ref.read(scannerControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AaharTheme.textHeadline,
            content: Text(
              err != null
                  ? 'Analysis error: $err'
                  : 'Could not analyze selected photo. Please ensure ingredients or nutrients are legible.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery import error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Camera Viewport (Active in both Barcode and Photo modes)
          Positioned.fill(
            child: MobileScanner(
              controller: _barcodeController,
              onDetect: _onBarcodeDetected,
            ),
          ),

          // Viewfinder reticle overlay
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Corner brackets
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF22C55E),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  // Animated laser sweep line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF22C55E),
                                Colors.white,
                                Color(0xFF22C55E),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Instruction text below viewport
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 340),
              child: Text(
                _selectedMode == 0
                    ? 'Point at barcode'
                    : 'Point at ingredient list & nutritional facts',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Top Bar with Mode Selector & Flash
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Flashlight toggle
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleTorch,
                  ),

                  // Segmented Toggle Pill
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleItem('Barcode Scan', 0),
                        _buildToggleItem('Label OCR Photo', 1),
                      ],
                    ),
                  ),

                  // Pro / Subscription badge
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                    icon: const Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFFF59E0B),
                    ),
                    onPressed: () => context.push('/subscription'),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Dock
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Gallery Picker
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 28,
                          color: AaharTheme.textHeadline,
                        ),
                        onPressed: _isProcessing ? null : _pickFromGallery,
                      ),
                      Text(
                        'Upload Image',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AaharTheme.textMuted,
                        ),
                      ),
                    ],
                  ),

                  // Shutter Button (Active in OCR Mode)
                  if (_selectedMode == 1)
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureLabelPhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AaharTheme.primaryGreen,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AaharTheme.primaryGreen,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AaharTheme.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: AaharTheme.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Auto-Scanning',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AaharTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),

                  // Street Food Intelligence Shortcut
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.fastfood_outlined,
                          size: 28,
                          color: AaharTheme.textHeadline,
                        ),
                        onPressed: () => context.go('/street-food'),
                      ),
                      Text(
                        'Street Food',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AaharTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Processing Loading Scrim
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AaharTheme.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Deconstructing Food Molecules...',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AaharTheme.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyzing FSSAI additives & nutrition',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AaharTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, int index) {
    final active = _selectedMode == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.black : Colors.white.withValues(alpha: 0.8),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
