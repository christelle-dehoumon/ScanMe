import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scanme_app/core/theme/theme.dart';
import 'package:scanme_app/core/utils/permission_utils.dart';
import 'package:scanme_app/core/utils/qr_link_utils.dart';
import 'package:scanme_app/features/contacts/scan_contact_result.dart';
import 'package:scanme_app/features/contacts/scan_social_result.dart';
import 'package:scanme_app/features/payments/payment_input_screen.dart';

class UniversalScannerScreen extends StatefulWidget {
  const UniversalScannerScreen({super.key});

  @override
  State<UniversalScannerScreen> createState() => _UniversalScannerScreenState();
}

class _UniversalScannerScreenState extends State<UniversalScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _hasProcessed = false;

  // Animation for scanner line
  late AnimationController _animationController;
  late Animation<double> _scannerLineAnimation;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scannerLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionUtils.requestCameraPermission(context);
    setState(() {
      _hasPermission = granted;
      _isCheckingPermission = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasProcessed) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? rawValue = barcodes.first.rawValue;
      if (rawValue != null) {
        _processQrCode(rawValue);
      }
    }
  }

  void _processQrCode(String data) {
    setState(() {
      _hasProcessed = true;
      _scannerController.stop();
    });

    // Determine type and navigate
    if (data.startsWith('BEGIN:VCARD')) {
      // Offline phone contact
      final contactMap = _parseVCard(data);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanContactResultScreen(contactData: contactMap),
        ),
      );
    } else if (data.startsWith('scanme://payment')) {
      // Payment QR link: scanme://payment?phone=...&operator=...&name=...
      final params = Uri.parse(data).queryParameters;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentInputScreen(paymentData: params),
        ),
      );
    } else if (QrLinkUtils.isSocialQrLink(data)) {
      final params = QrLinkUtils.parseSocialQrParams(data);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanSocialResultScreen(socialData: params),
        ),
      );
    } else if (_isWhatsAppLink(data)) {
      // WhatsApp link detected: https://wa.me/NUMBER or whatsapp://send?phone=NUMBER
      _openWhatsApp(data);
    } else {
      // Unknown text, show popup
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Format inconnu',
            style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          ),
          content: Text(
            'Données scannées : $data',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasProcessed = false;
                  _scannerController.start();
                });
              },
              child: const Text('Recommencer'),
            ),
          ],
        ),
      );
    }
  }

  Map<String, String> _parseVCard(String vcard) {
    final lines = vcard.split('\n');
    String name = 'Inconnu';
    String phone = '';

    for (var line in lines) {
      if (line.startsWith('FN:')) {
        name = line.substring(3).trim();
      } else if (line.startsWith('TEL;TYPE=CELL:')) {
        phone = line.substring(14).trim();
      } else if (line.startsWith('TEL:')) {
        phone = line.substring(4).trim();
      }
    }
    return {'name': name, 'phone': phone};
  }

  bool _isWhatsAppLink(String data) {
    return data.startsWith('https://wa.me/') ||
        data.startsWith('whatsapp://send?phone=');
  }

  Future<void> _openWhatsApp(String data) async {
    Uri? whatsappUri;
    
    if (data.startsWith('https://wa.me/')) {
      // Format: https://wa.me/NUMBER or https://wa.me/NUMBER?text=...
      whatsappUri = Uri.parse(data);
    } else if (data.startsWith('whatsapp://send?phone=')) {
      // Format: whatsapp://send?phone=NUMBER
      whatsappUri = Uri.parse(data);
    }

    if (whatsappUri != null) {
      try {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
        // App stays in background while WhatsApp opens
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur ouverture WhatsApp: $e'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _hasProcessed = false;
            _scannerController.start();
          });
        }
      }
    }
  }

  // Simulator/Emulator Scan Helper
  void _simulateScan(String type) {
    String mockData = '';
    if (type == 'contact') {
      mockData = 'BEGIN:VCARD\nVERSION:3.0\nFN:Ouédraogo Salif\nTEL:+226 70 88 99 00\nEND:VCARD';
    } else if (type == 'orange_payment') {
      mockData = 'scanme://payment?phone=%2B226+70+99+99+99&operator=Orange+Money&name=Boutique+K-Fast';
    } else if (type == 'wave_payment') {
      mockData = 'scanme://payment?phone=%2B226+55+44+33+22&operator=Wave&name=Taxi+Sya+Rapid';
    } else if (type == 'instagram_social') {
      mockData = 'scanme://social?ownerPhone=%2B226+76+11+22+33&network=Instagram&username=diallo_pro';
    } else if (type == 'snapchat_social') {
      mockData = 'scanme://social?ownerPhone=%2B226+62+55+66+77&network=Snapchat&username=chloe_snap';
    } else if (type == 'whatsapp_contact') {
      mockData = 'https://wa.me/22670889900';
    }

    _processQrCode(mockData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner un QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera scanner
          if (_hasPermission)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            )
          else if (!_isCheckingPermission)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Accès caméra requis',
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Veuillez accorder l\'autorisation d\'accès à votre caméra pour pouvoir scanner les QR codes de l\'application.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      child: const Text('Autoriser la caméra'),
                    )
                  ],
                ),
              ),
            ),

          // Custom Viewport Framing Overlay
          if (_hasPermission) ...[
            _buildViewportOverlay(),
            _buildActionControls(),
          ],

          // Simulation Panel (Visible always for testing/debugging in simulator environments)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.developer_mode_rounded, color: AppColors.primaryLight, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Simulateur de scan (Tests)',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSimButton('Contact', () => _simulateScan('contact')),
                        const SizedBox(width: 8),
                        _buildSimButton('Pay Orange', () => _simulateScan('orange_payment')),
                        const SizedBox(width: 8),
                        _buildSimButton('Pay Wave', () => _simulateScan('wave_payment')),
                        const SizedBox(width: 8),
                        _buildSimButton('Req Insta', () => _simulateScan('instagram_social')),
                        const SizedBox(width: 8),
                        _buildSimButton('Req Snap', () => _simulateScan('snapchat_social')),
                        const SizedBox(width: 8),
                        _buildSimButton('WhatsApp', () => _simulateScan('whatsapp_contact')),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSimButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildViewportOverlay() {
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    final double height = size.height;
    final double viewportSize = 250.0;
    final double left = (width - viewportSize) / 2;
    final double top = (height - viewportSize) / 2.3;

    return Stack(
      children: [
        // Darkened backgrounds around viewport
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: viewportSize,
                height: viewportSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Frame border corners
        Positioned(
          left: left,
          top: top,
          width: viewportSize,
          height: viewportSize,
          child: CustomPaint(
            painter: FrameBorderPainter(),
          ),
        ),

        // Animated Scanning Line
        Positioned(
          left: left + 10,
          top: top + 10 + (_scannerLineAnimation.value * (viewportSize - 20)),
          width: viewportSize - 20,
          height: 2,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
              color: AppColors.primaryLight,
            ),
          ),
        ),

        // Instructional text above viewport
        Positioned(
          top: top - 48,
          left: 24,
          right: 24,
          child: Center(
            child: Text(
              'Cadrez le code QR pour l\'analyser',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionControls() {
    return Positioned(
      top: 100,
      right: 20,
      child: Column(
        children: [
          // Flash Button
          _buildCircleButton(
            icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          const SizedBox(height: 16),
          // Camera Switch Button
          _buildCircleButton(
            icon: Icons.flip_camera_ios_rounded,
            onPressed: () {
              _scannerController.switchCamera();
              setState(() {
                _isFrontCamera = !_isFrontCamera;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

// Custom Painter to draw frame corners
class FrameBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double borderSize = 25.0;
    final double strokeWidth = 4.0;
    final double radius = 20.0;
    
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Top-Left Corner
    path.moveTo(0, borderSize);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.lineTo(borderSize, 0);

    // Top-Right Corner
    path.moveTo(size.width - borderSize, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, borderSize);

    // Bottom-Right Corner
    path.moveTo(size.width, size.height - borderSize);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(size.width - borderSize, size.height);

    // Bottom-Left Corner
    path.moveTo(borderSize, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, size.height - borderSize);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
