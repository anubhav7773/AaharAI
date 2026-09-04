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
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _lastDetectedCode;
  DateTime? _lastDetectedTime;
  String _processingMessage = '';

  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    // Warm up backend on camera open to ensure low latency
    ref.read(apiClientProvider).warmUpServer();

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 200.0).animate(
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
    final barcode = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (barcode == null || barcode.isEmpty) return;

    // Prevent spamming the same barcode within 3 seconds
    final now = DateTime.now();
    if (_lastDetectedCode == barcode &&
        _lastDetectedTime != null &&
        now.difference(_lastDetectedTime!) < const Duration(seconds: 3)) {
      return;
    }

    _lastDetectedCode = barcode;
    _lastDetectedTime = now;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Scanned code: $barcode\nChecking food database...';
    });

    try {
      final result = await ref
          .read(scannerControllerProvider.notifier)
          .processBarcode(barcode);

      if (!mounted) return;

      if (result != null) {
        context.push('/analysis', extra: result);
      } else {
        _showBarcodeNotFoundSheet(barcode);
      }
    } catch (_) {
      if (mounted) {
        _showBarcodeNotFoundSheet(barcode);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showBarcodeNotFoundSheet(String barcode) {
    final isNumericBarcode = RegExp(r'^\d{8,14}$').hasMatch(barcode);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AaharTheme.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isNumericBarcode
                        ? Icons.qr_code_scanner_rounded
                        : Icons.info_outline_rounded,
                    color: AaharTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isNumericBarcode
                      ? 'Product Not in Barcode Registry'
                      : 'Packaging / Batch Code Detected',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AaharTheme.textHeadline,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    barcode.length > 32
                        ? '${barcode.substring(0, 32)}...'
                        : barcode,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AaharTheme.textHeadline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isNumericBarcode
                      ? 'This barcode is not yet indexed in Open Food Facts. You can instantly analyze this food by taking a photo of the nutrition label or ingredient list!'
                      : 'This QR code contains manufacturing or batch details. To analyze this product, snap a photo of its ingredient list or nutrition facts with AI!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AaharTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AaharTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                    label: Text(
                      'Snap Label & Analyze with AI',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _captureLabelPhoto();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Scan Another Code',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AaharTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSheet(
    String message, {
    required bool isRetryable,
    VoidCallback? retryAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    color: Colors.amber.shade800,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Analysis Notice',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AaharTheme.textHeadline,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AaharTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                if (isRetryable && retryAction != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AaharTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        retryAction();
                      },
                      child: Text(
                        'Retry Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AaharTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

      setState(() {
        _isProcessing = true;
        _processingMessage =
            'Optimizing photo & analyzing with Gemini AI...';
      });

      final compressedFile =
          await ImageCompressor.compressForGemini(File(picked.path));

      final result = await ref
          .read(scannerControllerProvider.notifier)
          .processImage(compressedFile);

      if (result != null && mounted) {
        context.push('/analysis', extra: result);
      } else if (mounted) {
        final err = ref.read(scannerControllerProvider).error;
        _showErrorSheet(
          err != null
              ? '$err'
              : 'Could not extract nutrition information from this label. Please snap a clearer photo showing the nutrition facts table or ingredient list.',
          isRetryable: true,
          retryAction: _captureLabelPhoto,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSheet(
          'Failed to capture photo: $e',
          isRetryable: false,
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

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Scanning image for barcode or nutrition label...';
    });

    try {
      // 1. Try decoding barcode directly from the selected gallery image
      try {
        final barcodeCapture =
            await _barcodeController.analyzeImage(picked.path);
        final detectedBarcode =
            barcodeCapture?.barcodes.firstOrNull?.rawValue?.trim();
        if (detectedBarcode != null && detectedBarcode.isNotEmpty) {
          setState(() {
            _processingMessage =
                'Found barcode: $detectedBarcode\nFetching verified product data...';
          });
          final result = await ref
              .read(scannerControllerProvider.notifier)
              .processBarcode(detectedBarcode);
          if (result != null && mounted) {
            context.push('/analysis', extra: result);
            return;
          }
        }
      } catch (barcodeErr) {
        debugPrint('Gallery barcode detection skipped: $barcodeErr');
      }

      // 2. If no barcode or barcode not in DB, analyze packaging with Gemini AI
      setState(() {
        _processingMessage =
            'Analyzing nutrition label & ingredients with Gemini AI...';
      });

      final compressed =
          await ImageCompressor.compressForGemini(File(picked.path));
      final result = await ref
          .read(scannerControllerProvider.notifier)
          .processImage(compressed);

      if (result != null && mounted) {
        context.push('/analysis', extra: result);
      } else if (mounted) {
        final err = ref.read(scannerControllerProvider).error;
        _showErrorSheet(
          err != null
              ? '$err'
              : 'Could not analyze selected photo. Please ensure ingredients or nutrients are legible.',
          isRetryable: true,
          retryAction: _pickFromGallery,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSheet(
          'Gallery import error: $e',
          isRetryable: false,
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

          // Viewfinder Reticle Overlay
          Center(
            child: _selectedMode == 0
                ? _buildBarcodeReticle()
                : _buildPhotoReticle(),
          ),

          // Instruction Text Below Viewport
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.only(top: _selectedMode == 0 ? 260 : 360),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedMode == 0
                      ? 'Align barcode inside frame or tap button below'
                      : 'Point at ingredient list & nutritional facts',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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

                  // Interactive Shutter / AI Scan Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureLabelPhoto,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF22C55E),
                                Color(0xFF16A34A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _selectedMode == 0
                                  ? Icons.camera_alt_rounded
                                  : Icons.camera_alt,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedMode == 0 ? 'Snap & AI Scan' : 'Snap Label',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AaharTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
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

          // Processing Fullscreen Loading Scrim
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          color: AaharTheme.primaryGreen,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _processingMessage.isNotEmpty
                            ? _processingMessage
                            : 'AI Analyzing Food Molecules...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AaharTheme.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Analyzing FSSAI additives, allergens & nutrition',
                        textAlign: TextAlign.center,
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

  Widget _buildBarcodeReticle() {
    return SizedBox(
      width: 290,
      height: 200,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF22C55E),
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
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
                        color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                        blurRadius: 8,
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
    );
  }

  Widget _buildPhotoReticle() {
    return Container(
      width: 300,
      height: 320,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF22C55E),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.crop_free_rounded,
                  color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 6),
              Text(
                'Nutrition Facts / Ingredients',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
