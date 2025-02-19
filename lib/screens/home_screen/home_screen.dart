import 'package:flutter/material.dart';
import 'package:qr_code_scanner_example/screens/scanner_qr/scanner_qr_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ScannerQrScreen();
                },
              ),
            );
          },
          child: Text("Scanner page"),
        ),
      ),
    );
  }
}
