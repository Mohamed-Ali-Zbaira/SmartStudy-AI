import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/groq_config.dart';
import '../screens/quiz_screen.dart';

class GroqService {
  final String _baseUrl = GroqConfig.baseUrl;

  // ─── Générer un résumé structuré ────────────────────────
  Future<Map<String, dynamic>> generateSummary(String pdfText) async {
    try {
      if (pdfText.isEmpty) {
        return _getDefaultSummary('Le texte du document est vide.');
      }

      final truncatedText = pdfText.length > 4000
          ? pdfText.substring(0, 4000)
          : pdfText;

      final prompt = '''
Tu es un assistant pédagogique expert. Analyse le texte suivant et génère un résumé structuré en français.

TEXTE À ANALYSER :
$truncatedText

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte :
{
  "executive_summary": "Résumé exécutif de 3-4 phrases qui capture l'essentiel",
  "key_points": ["Point clé 1", "Point clé 2", "Point clé 3", "Point clé 4", "Point clé 5"],
  "definitions": {
    "Terme 1": "Définition courte",
    "Terme 2": "Définition courte"
  },
  "exam_tips": ["Conseil pour l'examen 1", "Conseil pour l'examen 2", "Conseil pour l'examen 3"],
  "difficulty_level": "Facile/Moyen/Difficile"
}

IMPORTANT : Retourne UNIQUEMENT le JSON, sans texte avant ou après.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un assistant pédagogique qui génère des résumés structurés en JSON.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.3,
          'max_tokens': 2048,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseJSONResponse(content);
      } else {
        return _getDefaultSummary('Erreur API Groq: ${response.statusCode}');
      }
    } catch (e) {
      return _getDefaultSummary('Erreur de connexion');
    }
  }

  // ─── Générer un quiz ────────────────────────────────────
  Future<List<QuizQuestion>> generateQuiz(String pdfText, {int numberOfQuestions = 10}) async {
    try {
      if (pdfText.isEmpty) return _getFallbackQuestions();

      final truncatedText = pdfText.length > 6000
          ? pdfText.substring(0, 6000)
          : pdfText;

      final prompt = '''
Tu es un professeur qui crée un QCM. Base-toi UNIQUEMENT sur le texte fourni pour générer $numberOfQuestions questions à choix multiples en français.

TEXTE DU COURS :
$truncatedText

Retourne UNIQUEMENT un tableau JSON comme ceci :
[
  {
    "question": "Quelle est la capitale de la France ?",
    "options": ["Londres", "Paris", "Berlin", "Madrid"],
    "correct_index": 1,
    "explanation": "Paris est la capitale de la France."
  }
]
''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un générateur de quiz. Tu réponds UNIQUEMENT avec un tableau JSON valide.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.7,
          'max_tokens': 4096,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final questions = _parseQuizResponse(content);
        if (questions.isEmpty) return _getFallbackQuestions();
        return questions;
      }
      return _getFallbackQuestions();
    } catch (e) {
      return _getFallbackQuestions();
    }
  }

  // ✅ Chat avec le document
  Future<String> chatWithDocument(String pdfText, String question, {List<Map<String, String>>? history}) async {
    try {
      if (pdfText.isEmpty) {
        return 'Le texte du document n\'est pas disponible. Veuillez réessayer.';
      }

      final truncatedText = pdfText.length > 6000
          ? pdfText.substring(0, 6000)
          : pdfText;

      // Construire les messages avec l'historique
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': '''
Tu es un assistant pédagogique qui répond aux questions sur un document.
Règles :
- Réponds UNIQUEMENT en te basant sur le document fourni.
- Si l'information n'est pas dans le document, dis poliment que tu ne peux pas répondre.
- Sois concis et clair.
- Utilise le français.
- Formatte ta réponse avec des puces si nécessaire.
'''
        },
        {
          'role': 'user',
          'content': 'Voici le document de référence :\n\n$truncatedText\n\nConfirme que tu as bien reçu le document.'
        },
        {
          'role': 'assistant',
          'content': 'J\'ai bien reçu le document. Je suis prêt à répondre à vos questions en me basant uniquement sur son contenu.'
        },
      ];

      // Ajouter l'historique de conversation
      if (history != null && history.isNotEmpty) {
        // Prendre les 6 derniers messages pour garder le contexte
        final recentHistory = history.length > 6
            ? history.sublist(history.length - 6)
            : history;
        messages.addAll(recentHistory);
      }

      // Ajouter la question actuelle
      messages.add({
        'role': 'user',
        'content': question,
      });

      print('💬 Chat request - Messages count: ${messages.length}');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('✅ Chat response received (${content.length} chars)');
        return content;
      } else {
        print('❌ Chat API Error: ${response.statusCode}');
        return 'Désolé, je n\'ai pas pu traiter votre question. Veuillez réessayer.';
      }
    } catch (e) {
      print('❌ Chat Exception: $e');
      return 'Une erreur est survenue. Vérifiez votre connexion internet.';
    }
  }

  // ─── Parser la réponse du quiz ──────────────────────────
  List<QuizQuestion> _parseQuizResponse(String content) {
    try {
      String cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
      final startIndex = cleaned.indexOf('[');
      final endIndex = cleaned.lastIndexOf(']');
      if (startIndex == -1 || endIndex == -1) return [];
      cleaned = cleaned.substring(startIndex, endIndex + 1);
      final List<dynamic> jsonList = jsonDecode(cleaned);

      return jsonList.map((item) {
        List<String> options = item['options'] is List ? List<String>.from(item['options']) : [];
        while (options.length < 4) options.add('Option ${options.length + 1}');
        if (options.length > 4) options = options.sublist(0, 4);
        int correctIndex = item['correct_index'] ?? 0;
        if (correctIndex < 0 || correctIndex >= options.length) correctIndex = 0;

        return QuizQuestion(
          question: item['question']?.toString() ?? 'Question non disponible',
          options: options,
          correctIndex: correctIndex,
          explanation: item['explanation']?.toString() ?? 'Pas d\'explication disponible',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Parser JSON résumé ─────────────────────────────
  Map<String, dynamic> _parseJSONResponse(String text) {
    try {
      final jsonStr = _extractJSON(text);
      final json = jsonDecode(jsonStr);
      return {
        'executiveSummary': json['executive_summary']?.toString() ?? 'Résumé généré.',
        'keyPoints': json['key_points'] is List ? List<String>.from(json['key_points']) : [],
        'definitions': json['definitions'] is Map ? Map<String, String>.from(json['definitions']) : {},
        'examTips': json['exam_tips'] is List ? List<String>.from(json['exam_tips']) : [],
        'difficultyLevel': json['difficulty_level']?.toString() ?? 'Moyen',
      };
    } catch (e) {
      return {
        'executiveSummary': text,
        'keyPoints': [],
        'definitions': {},
        'examTips': [],
        'difficultyLevel': 'Moyen',
      };
    }
  }

  String _extractJSON(String text) {
    String cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final startIndex = cleaned.indexOf(RegExp(r'[\[\{]'));
    final endIndex = cleaned.lastIndexOf(RegExp(r'[\]\}]'));
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return cleaned.substring(startIndex, endIndex + 1);
    }
    return cleaned;
  }

  List<QuizQuestion> _getFallbackQuestions() {
    return [
      QuizQuestion(question: 'Question 1', options: ['A', 'B', 'C', 'D'], correctIndex: 0, explanation: 'Explication'),
      QuizQuestion(question: 'Question 2', options: ['A', 'B', 'C', 'D'], correctIndex: 1, explanation: 'Explication'),
      QuizQuestion(question: 'Question 3', options: ['A', 'B', 'C', 'D'], correctIndex: 2, explanation: 'Explication'),
      QuizQuestion(question: 'Question 4', options: ['A', 'B', 'C', 'D'], correctIndex: 3, explanation: 'Explication'),
      QuizQuestion(question: 'Question 5', options: ['A', 'B', 'C', 'D'], correctIndex: 0, explanation: 'Explication'),
    ];
  }

  Map<String, dynamic> _getDefaultSummary(String reason) {
    return {
      'executiveSummary': 'Le résumé n\'a pas pu être généré. $reason',
      'keyPoints': ['Service indisponible'],
      'definitions': {},
      'examTips': ['Réessayez plus tard'],
      'difficultyLevel': 'N/A',
    };
  }
}