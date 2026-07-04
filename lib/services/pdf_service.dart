import 'dart:io';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';

class PdfService {

  // ─── Extraire le texte d'un PDF ──────────────────────────
  Future<String> extractText(File pdfFile) async {
    try {
      final pdfDoc = await PDFDoc.fromFile(pdfFile);
      final text = await pdfDoc.text;
      return text;
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction du texte: $e');
    }
  }

  // ─── Compter le nombre de pages ──────────────────────────
  Future<int> getPageCount(File pdfFile) async {
    try {
      final pdfDoc = await PDFDoc.fromFile(pdfFile);
      final pages = await pdfDoc.pages;
      return pages.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des pages: $e');
    }
  }

  // ─── Extraire le texte par page ──────────────────────────
  Future<List<String>> extractTextByPage(File pdfFile) async {
    try {
      final pdfDoc = await PDFDoc.fromFile(pdfFile);
      final pages = await pdfDoc.pages;
      final List<String> pageTexts = [];

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final pageText = await page.text;
        pageTexts.add(pageText);
      }

      return pageTexts;
    } catch (e) {
      throw Exception('Erreur lors de l\'extraction par page: $e');
    }
  }

  // ─── Vérifier si le PDF est valide ──────────────────────
  Future<bool> isValidPDF(File pdfFile) async {
    try {
      final pdfDoc = await PDFDoc.fromFile(pdfFile);
      final pages = await pdfDoc.pages;
      return pages.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}