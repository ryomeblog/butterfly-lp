import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// カメラで QR コードを読み、その文字列を返す（同期の合言葉・共有の URL）。
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key, required this.title});

  final String title;

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final v = capture.barcodes.firstOrNull?.rawValue;
          if (v == null) return;
          _done = true;
          Navigator.of(context).pop(v);
        },
      ),
    );
  }
}
