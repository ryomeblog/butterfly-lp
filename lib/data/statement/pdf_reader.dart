import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import 'pdf_lines.dart';
import 'statement.dart';

/// 文字が入った PDF から、見た目どおりの行を取り出す（設計書 3.11。スキャンした PDF は読めない）。
Future<List<String>> readPdfLines(List<int> bytes) async {
  await pdfrxFlutterInitialize();
  final PdfDocument doc;
  try {
    doc = await PdfDocument.openData(Uint8List.fromList(bytes));
  } catch (_) {
    throw const StatementFormatException('PDF を開けませんでした');
  }
  try {
    final lines = <String>[];
    for (final page in doc.pages) {
      final text = await page.loadStructuredText();
      final n = text.fullText.length < text.charRects.length
          ? text.fullText.length
          : text.charRects.length;
      lines.addAll(
        buildLines([
          for (var i = 0; i < n; i++)
            PositionedChar(
              text.fullText[i],
              text.charRects[i].left,
              text.charRects[i].right,
              text.charRects[i].bottom,
              text.charRects[i].top,
            ),
        ]),
      );
    }
    if (lines.isEmpty) {
      throw const StatementFormatException(
        'PDF に文字が入っていません（写真やスキャンの PDF は読めません）',
      );
    }
    return lines;
  } finally {
    await doc.dispose();
  }
}
