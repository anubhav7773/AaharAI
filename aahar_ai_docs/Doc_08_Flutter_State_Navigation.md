Markdown# Doc 08: Flutter Frontend Architecture, State Management & Camera Layer

## 1. Architectural Foundation & Package Dependencies
The mobile client uses **Feature-First Clean Architecture** with **Riverpod 2.x (code generation)** for deterministic, reactive state management and **GoRouter** for declarative, auth-guarded routing.

### Production `pubspec.yaml` Dependencies
```yaml
name: aahar_ai
description: "AI-driven food transparency and nutritional intelligence engine."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management & Reactive Di
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Routing & Deep Linking
  go_router: ^14.0.1

  # Backend, Auth & Storage
  supabase_flutter: ^2.5.6
  firebase_core: ^2.30.1
  firebase_auth: ^4.19.4
  google_sign_in: ^6.2.1

  # Hardware, Camera & Scanning
  mobile_scanner: ^5.1.1
  camera: ^0.10.5+9
  image_picker: ^1.1.0
  image: ^4.1.7 # In-memory image downscaling/compression

  # Networking & Caching
  dio: ^5.4.3+1
  hive_flutter: ^1.1.0
  path_provider: ^2.1.3

  # UI Utility, Icons & AdMob
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1
  google_mobile_ads: ^5.1.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10
2. Declarative Navigation & Auth Guards (lib/core/router/app_router.dart)GoRouter inspects the authenticated state from Firebase/Supabase and gates unauthorized access away from scanner and diary views.  Dartimport 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/analysis/presentation/analysis_screen.dart';
import '../../features/street_food/presentation/street_food_screen.dart';
import '../../features/diary/presentation/diary_screen.dart';
import '../../features/scanner/presentation/manual_crop_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = FirebaseAuth.instance.authStateChanges();

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/scanner',
    redirect: (BuildContext context, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;
      final loggingIn = state.matchedLocation == '/login';

      if (user == null && !loggingIn) {
        return '/login';
      }
      if (user != null && loggingIn) {
        return '/scanner';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const UniversalScannerScreen(),
          ),
          GoRoute(
            path: '/street-food',
            builder: (context, state) => const StreetFoodIndexScreen(),
          ),
          GoRoute(
            path: '/diary',
            builder: (context, state) => const DailyDiaryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/analysis',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnalysisResultScreen(payload: extra);
        },
      ),
      GoRoute(
        path: '/crop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final imagePath = state.extra as String;
          return ManualCropScreen(imagePath: imagePath);
        },
      ),
    ],
  );
}

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/street-food')) currentIndex = 1;
    if (location.startsWith('/diary')) currentIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/scanner');
              break;
            case 1:
              context.go('/street-food');
              break;
            case 2:
              context.go('/diary');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.fastfood_outlined), label: 'Street Food'),
          NavigationDestination(icon: Icon(Icons.book_outlined), label: 'Diary'),
        ],
      ),
    );
  }
}
3. High-Performance Network Client (lib/core/network/api_client.dart)Dio instance configured with automated warming ping to Render, custom headers for Open Food Facts compliance, and exponential backoff retry interceptors:  Dartimport 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio dio;
  static const String baseUrl = '[https://aaharai-backend.onrender.com](https://aaharai-backend.onrender.com)'; // Render free-tier URL[cite: 1]

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 25), // Accommodate Gemini cold inference[cite: 1]
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AaharAi-Mobile/1.0',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          // Automatic 1-time retry for Render spin-up delays or 503 drops[cite: 1, 2]
          if (err.type == DioExceptionType.connectionTimeout ||
              err.response?.statusCode == 503 ||
              err.response?.statusCode == 504) {
            try {
              final response = await dio.request(
                err.requestOptions.path,
                options: Options(
                  method: err.requestOptions.method,
                  headers: err.requestOptions.headers,
                ),
                data: err.requestOptions.data,
                queryParameters: err.requestOptions.queryParameters,
              );
              return handler.resolve(response);
            } catch (_) {}
          }
          return handler.next(err);
        },
      ),
    );
  }

  Future<void> warmUpServer() async {
    try {
      await dio.get('/health'); // Non-blocking health ping to awake Render instance[cite: 1]
    } catch (_) {}
  }

  Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    final res = await dio.get('/api/v1/scan/barcode/$barcode');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadLabelImage(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'ingredient_label.jpg',
      ),
    });
    final res = await dio.post('/api/v1/scan/vision', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchStreetFoodAnalysis(String dishName) async {
    final res = await dio.get(
      '/api/v1/scan/street-food',
      queryParameters: {'dish_name': dishName},
    );
    return res.data as Map<String, dynamic>;
  }
}
4. Hardware Camera & Barcode Controller (lib/features/scanner/presentation/scanner_screen.dart)Unified camera interface switching between continuous MobileScanner (Barcodes) and high-definition CameraImage capturing (OCR photo)[cite: 1]:Dartimport 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../controllers/scanner_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_compressor.dart';

class UniversalScannerScreen extends ConsumerStatefulWidget {
  const UniversalScannerScreen({super.key});

  @override
  ConsumerState<UniversalScannerScreen> createState() => _UniversalScannerScreenState();
}

class _UniversalScannerScreenState extends ConsumerState<UniversalScannerScreen> {
  int _selectedMode = 0; // 0 = Barcode Scan, 1 = Label OCR Photo
  final MobileScannerController _barcodeController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  CameraController? _photoController;
  List<CameraDescription>? _cameras;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    ref.read(apiClientProvider).warmUpServer(); // Background warm up ping[cite: 1]
    _initPhotoCamera();
  }

  Future<void> _initPhotoCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _photoController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _photoController!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _photoController?.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);
    final result = await ref.read(scannerControllerProvider.notifier).processBarcode(barcode);
    setState(() => _isProcessing = false);

    if (result != null && mounted) {
      context.push('/analysis', extra: result);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product not found in barcode database. Please snap a photo.'),
          action: SnackBarAction(
            label: 'Snap Label',
            onPressed: () => setState(() => _selectedMode = 1),
          ),
        ),
      );
    }
  }

  Future<void> _captureLabelPhoto() async {
    if (_photoController == null || !_photoController!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final xFile = await _photoController!.takePicture();
      final compressedFile = await ImageCompressor.compressForGemini(File(xFile.path)); //

      final result = await ref.read(scannerControllerProvider.notifier).processImage(compressedFile);
      if (result != null && mounted) {
        context.push('/analysis', extra: result);
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
      final compressed = await ImageCompressor.compressForGemini(File(picked.path)); //[cite: 2]
      final result = await ref.read(scannerControllerProvider.notifier).processImage(compressed);
      if (result != null && mounted) {
        context.push('/analysis', extra: result);
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
          // Dynamic Camera Viewport
          Positioned.fill(
            child: _selectedMode == 0
                ? MobileScanner(
                    controller: _barcodeController,
                    onDetect: _onBarcodeDetected,
                  )
                : (_photoController != null && _photoController!.value.isInitialized)
                    ? CameraPreview(_photoController!)
                    : const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
          ),

          // Laser scan box overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF22C55E), width: 2.5),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          // Header Selector Pill
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleItem('Barcode', 0),
                    _buildToggleItem('Label OCR Photo', 1),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Control Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, size: 28),
                    onPressed: _isProcessing ? null : _pickFromGallery,
                  ),
                  if (_selectedMode == 1)
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureLabelPhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1B5E20), width: 4),
                        ),
                        child: Center(
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Align barcode within frame',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () => context.go('/street-food'),
                  ),
                ],
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'AI Analyzing Food Molecules...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
5. Client-Side Image Preprocessing (lib/core/utils/image_compressor.dart)Preprocesses camera pictures to enforce maximum dimension boundaries ($1024 \times 1024$), capping Gemini 2.5 Flash token consumption within $258 - 1032$ tokens while maintaining text legibility[cite: 2]:Dartimport 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static Future<File> compressForGemini(File rawFile) async {
    final bytes = await rawFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return rawFile;

    // Constrain resolution boundaries to 1024px maximum edge[cite: 2]
    img.Image resized = decoded;
    if (decoded.width > 1024 || decoded.height > 1024) {
      resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? 1024 : null,
        height: decoded.height >= decoded.width ? 1024 : null,
        interpolation: img.Interpolation.average,
      );
    }

    final compressedBytes = img.encodeJpg(resized, quality: 80);
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(compressedBytes);

    return targetFile;
  }
}
6. Scanner Business State Machine (lib/features/scanner/controllers/scanner_controller.dart)Riverpod AsyncNotifier managing the network execution, fallback cascades, and error handling:Dartimport 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'scanner_controller.g.dart';

@riverpod
class ScannerController extends _$ScannerController {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>?> processBarcode(String barcode) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.scanBarcode(barcode);
      state = const AsyncValue.data(null);
      return data;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }

  Future<Map<String, dynamic>?> processImage(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiClientProvider);
      final data = await client.uploadLabelImage(imageFile);
      state = const AsyncValue.data(null);
      return data;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      return null;
    }
  }
}