import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class ScannerQrScreen extends StatefulWidget {
  const ScannerQrScreen({super.key});

  @override
  State<ScannerQrScreen> createState() => _ScannerQrScreenState();
}

class _ScannerQrScreenState extends State<ScannerQrScreen> {
  final MobileScannerController _mobileScannerController =
      MobileScannerController(detectionSpeed: DetectionSpeed.normal);

  @override
  void initState() {
    _mobileScannerController.addListener(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scaner page")),
      body: MobileScanner(
        fit: BoxFit.cover,
        controller: _mobileScannerController,
        onDetect: (capture) async {
          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _mobileScannerController.pause();
              try {
                final Uri uri = Uri.parse(barcode.rawValue!);

                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {}
              } catch (error) {
                debugPrint("Error: $error -----------");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Nimadir hato"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint("asdfa");
          _mobileScannerController.start();
        },
      ),
    );
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
  }
}
