import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractorService {

  // ─── Extraire le texte d'un PDF depuis des bytes ─────────
  Future<Map<String, dynamic>> extractTextFromBytes(Uint8List bytes) async {
    try {
      print('📄 Extracting text with Syncfusion...');
      print('📄 Bytes length: ${bytes.length}');

      // Charger le document PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // ✅ Utiliser PdfTextExtractor pour extraire le texte
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      final StringBuffer allText = StringBuffer();
      int pageCount = document.pages.count;

      print('📄 Number of pages: $pageCount');

      // Extraire le texte de toutes les pages
      for (int i = 0; i < pageCount; i++) {
        final String pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);

        if (pageText.isNotEmpty) {
          allText.writeln(pageText);
          allText.writeln('\n--- Page ${i + 1} ---\n');
        }
      }

      // Fermer le document
      document.dispose();

      final extractedText = allText.toString().trim();
      print('✅ Extracted text length: ${extractedText.length}');

      if (extractedText.isEmpty) {
        return {
          'success': false,
          'text': '',
          'pageCount': pageCount,
          'error': 'Aucun texte trouvé dans le PDF (peut-être un scan)',
        };
      }

      // Afficher un aperçu
      final preview = extractedText.length > 200
          ? '${extractedText.substring(0, 200)}...'
          : extractedText;
      print('✅ Preview: $preview');

      return {
        'success': true,
        'text': extractedText,
        'pageCount': pageCount,
      };
    } catch (e) {
      print('❌ Syncfusion extraction error: $e');
      return {
        'success': false,
        'text': '',
        'pageCount': 0,
        'error': e.toString(),
      };
    }
  }

  // ─── Version simplifiée : extraire tout le texte ─────────
  Future<String> extractAllText(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);

      // Extraire tout le texte d'un coup
      final String text = extractor.extractText();

      document.dispose();
      return text.trim();
    } catch (e) {
      print('❌ Extract all text error: $e');
      return '';
    }
  }

  // ─── Vérifier si le PDF contient du texte ────────────────
  Future<bool> hasText(Uint8List bytes) async {
    try {
      final text = await extractAllText(bytes);
      return text.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ─── Obtenir le nombre de pages ──────────────────────────
  Future<int> getPageCount(Uint8List bytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (e) {
      return 0;
    }
  }
}