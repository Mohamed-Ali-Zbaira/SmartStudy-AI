import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

// ════════════════════════════════════════════════════════════
//  GEMINI SERVICE — Version corrigée avec diagnostics complets
// ════════════════════════════════════════════════════════════
class GeminiService {
  // ✅ v1beta est la version stable correcte pour l'API Gemini
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // ✅ Liste de modèles disponibles, du plus rapide au plus capable
  static const List<String> _models = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];

  // ════════════════════════════════════════════════════════
  //  MÉTHODE PRINCIPALE : Générer un résumé
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> generateSummary(String pdfText) async {
    // ── Vérification préliminaire ──────────────────────────
    if (GeminiConfig.apiKey.isEmpty ||
        GeminiConfig.apiKey == 'VOTRE_CLE_API_GEMINI') {
      print('❌ ERREUR : Clé API Gemini non configurée dans supabase_config.dart');
      return _errorSummary(
        'Clé API Gemini manquante. Ajoutez-la dans lib/config/supabase_config.dart',
      );
    }

    if (pdfText.trim().isEmpty) {
      print('⚠️  Texte PDF vide');
      return _errorSummary(
        'Le texte du PDF est vide. Re-uploadez le document.',
      );
    }

    print('═══════════════════════════════════════════');
    print('🤖 GeminiService.generateSummary()');
    print('📄 Texte reçu : ${pdfText.length} caractères');
    print('🔑 Clé API : ${GeminiConfig.apiKey.substring(0, 10)}...');
    print('═══════════════════════════════════════════');

    final prompt = _buildPrompt(pdfText);

    // ── Essai avec chaque modèle ───────────────────────────
    for (final model in _models) {
      print('\n📡 Essai avec le modèle : $model');
      try {
        final result = await _callAPI(model: model, prompt: prompt);
        if (result != null) {
          print('✅ Succès avec : $model');
          return result;
        }
      } on _ApiKeyException catch (e) {
        // Clé invalide → inutile d'essayer les autres modèles
        print('🔑 Clé API invalide : ${e.message}');
        return _errorSummary(
          '🔑 Clé API Gemini invalide (erreur 403).\n'
              'Vérifiez votre clé sur https://aistudio.google.com/apikey\n'
              'et assurez-vous que l\'API "Generative Language" est activée.',
        );
      } on _QuotaException {
        print('⚠️  Quota dépassé pour $model, essai du suivant...');
        continue;
      } on _ModelNotFoundException {
        print('⚠️  Modèle $model non disponible, essai du suivant...');
        continue;
      } catch (e) {
        print('⚠️  Erreur inattendue avec $model : $e');
        continue;
      }
    }

    return _errorSummary(
      'Tous les modèles Gemini ont échoué.\n'
          'Causes possibles :\n'
          '• Clé API expirée ou invalide\n'
          '• Quota journalier dépassé\n'
          '• Pas de connexion internet\n'
          'Vérifiez les logs Flutter pour plus de détails.',
    );
  }

  // ════════════════════════════════════════════════════════
  //  APPEL API
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _callAPI({
    required String model,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/$model:generateContent?key=${GeminiConfig.apiKey}',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 2048,
        'topP': 0.8,
      },
    });

    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 45));

    print('  → HTTP ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        return _parseResponse(response.body);

      case 400:
        final msg = _extractErrorMessage(response.body);
        print('  ❌ 400 Bad Request : $msg');
        return null;

      case 403:
        final msg = _extractErrorMessage(response.body);
        print('  ❌ 403 Forbidden : $msg');
        throw _ApiKeyException(msg);

      case 404:
        print('  ❌ 404 Modèle non trouvé : $model');
        throw _ModelNotFoundException();

      case 429:
        final msg = _extractErrorMessage(response.body);
        print('  ❌ 429 Quota dépassé : $msg');
        throw _QuotaException();

      case 500:
      case 503:
        print('  ❌ ${response.statusCode} Erreur serveur Gemini');
        return null;

      default:
        print('  ❌ HTTP ${response.statusCode} : ${response.body.substring(0, response.body.length.clamp(0, 200))}');
        return null;
    }
  }

  // ════════════════════════════════════════════════════════
  //  PARSING DE LA RÉPONSE
  // ════════════════════════════════════════════════════════
  Map<String, dynamic>? _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        print('  ⚠️  Aucun candidat dans la réponse');
        return null;
      }

      final candidate = candidates[0] as Map<String, dynamic>;
      final finishReason = candidate['finishReason']?.toString() ?? '';

      if (finishReason == 'SAFETY') {
        print('  ⚠️  Réponse bloquée pour raisons de sécurité');
        return null;
      }

      final parts = candidate['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        print('  ⚠️  Réponse vide');
        return null;
      }

      final rawText = parts[0]['text']?.toString() ?? '';
      if (rawText.isEmpty) return null;

      print('  📝 Texte brut reçu (${rawText.length} chars)');
      return _parseJSON(rawText);
    } catch (e) {
      print('  ❌ Erreur parsing réponse : $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  //  PARSING DU JSON RETOURNÉ PAR GEMINI
  // ════════════════════════════════════════════════════════
  Map<String, dynamic> _parseJSON(String text) {
    try {
      // Nettoyage des balises markdown
      String cleaned = text
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      // Extraction de l'objet JSON
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');

      if (start == -1 || end == -1 || end <= start) {
        print('  ⚠️  Pas de JSON trouvé, utilisation du texte brut');
        return _rawTextSummary(text);
      }

      cleaned = cleaned.substring(start, end + 1);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      return {
        'executiveSummary': _str(json, [
          'executive_summary',
          'executiveSummary',
          'résumé',
          'summary',
        ]) ??
            'Résumé généré avec succès.',
        'keyPoints': _list(json, ['key_points', 'keyPoints', 'points_cles']),
        'definitions': _map(json, ['definitions', 'définitions']),
        'examTips': _list(json, ['exam_tips', 'examTips', 'conseils']),
        'difficultyLevel': _str(json, [
          'difficulty_level',
          'difficultyLevel',
          'niveau',
        ]) ??
            'Moyen',
      };
    } catch (e) {
      print('  ⚠️  JSON invalide : $e');
      return _rawTextSummary(text);
    }
  }

  // ════════════════════════════════════════════════════════
  //  CONSTRUCTION DU PROMPT
  // ════════════════════════════════════════════════════════
  String _buildPrompt(String text) {
    final truncated = _truncate(text, 8000);

    return '''
Tu es un assistant pédagogique expert. Analyse ce texte de cours universitaire et génère un résumé structuré en français.

TEXTE :
"""
$truncated
"""

Réponds UNIQUEMENT avec un objet JSON valide, sans markdown ni texte autour. Structure exacte :
{
  "executive_summary": "Résumé complet du cours en 3 à 5 phrases claires.",
  "key_points": ["Concept clé 1", "Concept clé 2", "Concept clé 3", "Concept clé 4"],
  "definitions": {
    "Terme important": "Sa définition précise",
    "Autre terme": "Sa définition"
  },
  "exam_tips": ["Conseil pratique pour l'examen 1", "Conseil 2"],
  "difficulty_level": "Moyen"
}

Règles :
- difficulty_level = "Facile", "Moyen" ou "Difficile" uniquement
- key_points = 3 à 6 éléments
- definitions = 2 à 5 termes importants du cours
- exam_tips = 2 à 4 conseils pratiques
- JSON valide uniquement, rien d'autre
''';
  }

  // ════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════

  String? _str(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] != null) return json[k].toString();
    }
    return null;
  }

  List<String> _list(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] is List) {
        return List<String>.from((json[k] as List).map((e) => e.toString()));
      }
    }
    return [];
  }

  Map<String, String> _map(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] is Map) {
        return Map<String, String>.from(
          (json[k] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
    }
    return {};
  }

  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    final half = max ~/ 2;
    return '${text.substring(0, half)}\n\n[...texte tronqué...]\n\n${text.substring(text.length - half ~/ 2)}';
  }

  String _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body);
      return json['error']?['message']?.toString() ??
          body.substring(0, body.length.clamp(0, 150));
    } catch (_) {
      return body.substring(0, body.length.clamp(0, 150));
    }
  }

  Map<String, dynamic> _rawTextSummary(String text) {
    final s = text.length > 600 ? '${text.substring(0, 600)}...' : text;
    return {
      'executiveSummary': s,
      'keyPoints': <String>['Consultez le document original'],
      'definitions': <String, String>{},
      'examTips': <String>['Relisez attentivement le cours'],
      'difficultyLevel': 'Moyen',
    };
  }

  Map<String, dynamic> _errorSummary(String message) {
    return {
      'executiveSummary': message,
      'keyPoints': <String>['Service indisponible - réessayez plus tard'],
      'definitions': <String, String>{},
      'examTips': <String>[
        'Vérifiez les logs Flutter pour diagnostiquer le problème'
      ],
      'difficultyLevel': 'N/A',
    };
  }
}

// ════════════════════════════════════════════════════════════
//  EXCEPTIONS INTERNES
// ════════════════════════════════════════════════════════════
class _ApiKeyException implements Exception {
  final String message;
  _ApiKeyException(this.message);
}

class _ModelNotFoundException implements Exception {}

class _QuotaException implements Exception {}