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
              'content': 'Tu es un assistant pédagogique qui génère des résumés structurés en JSON. Retourne UNIQUEMENT du JSON valide.'
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
        print('❌ Groq API Error: ${response.statusCode} - ${response.body}');
        return _getDefaultSummary('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Groq Exception: $e');
      return _getDefaultSummary('Erreur de connexion');
    }
  }

  // ─── Générer un quiz ────────────────────────────────────
  Future<List<QuizQuestion>> generateQuiz(String pdfText, {int numberOfQuestions = 10}) async {
    try {
      if (pdfText.isEmpty) {
        print('❌ PDF text is empty');
        return _getFallbackQuestions();
      }

      final truncatedText = pdfText.length > 6000
          ? pdfText.substring(0, 6000)
          : pdfText;

      final prompt = '''
Tu es un professeur qui crée un QCM pour évaluer des étudiants. 
Base-toi UNIQUEMENT sur le texte fourni pour générer $numberOfQuestions questions à choix multiples en français.

TEXTE DU COURS :
$truncatedText

IMPORTANT : 
- Génère EXACTEMENT $numberOfQuestions questions.
- Chaque question doit avoir 4 options (A, B, C, D).
- L'index de la bonne réponse doit être 0, 1, 2 ou 3.
- Fournis une explication courte pour chaque réponse.

Retourne UNIQUEMENT un tableau JSON comme ceci :
[
  {
    "question": "Quelle est la capitale de la France ?",
    "options": ["Londres", "Paris", "Berlin", "Madrid"],
    "correct_index": 1,
    "explanation": "Paris est la capitale de la France."
  }
]

Ne mets PAS de texte avant ou après le JSON. Juste le tableau JSON.
''';

      print('🦙 Sending quiz request to Groq...');
      print('📄 Text length: ${truncatedText.length} chars');

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
              'content': 'Tu es un générateur de quiz. Tu réponds UNIQUEMENT avec un tableau JSON valide. Pas de texte avant ou après.'
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

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        print('📝 Raw response: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');

        final questions = _parseQuizResponse(content);

        if (questions.isEmpty) {
          print('⚠️ No questions parsed, using fallback');
          return _getFallbackQuestions();
        }

        print('✅ Generated ${questions.length} questions');
        return questions;
      } else {
        print('❌ Groq API Error: ${response.statusCode} - ${response.body}');
        return _getFallbackQuestions();
      }
    } catch (e) {
      print('❌ Groq Quiz Exception: $e');
      return _getFallbackQuestions();
    }
  }

  // ─── Parser la réponse du quiz ──────────────────────────
  List<QuizQuestion> _parseQuizResponse(String content) {
    try {
      // Nettoyer la réponse
      String cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      // Trouver le début du tableau JSON
      final startIndex = cleaned.indexOf('[');
      final endIndex = cleaned.lastIndexOf(']');

      if (startIndex == -1 || endIndex == -1) {
        print('❌ No JSON array found in response');
        return [];
      }

      cleaned = cleaned.substring(startIndex, endIndex + 1);
      print('🧹 Cleaned JSON: ${cleaned.substring(0, cleaned.length > 200 ? 200 : cleaned.length)}...');

      final List<dynamic> jsonList = jsonDecode(cleaned);

      return jsonList.map((item) {
        // Vérifier et corriger les options
        List<String> options = [];
        if (item['options'] is List) {
          options = List<String>.from(item['options']);
        }

        // Si pas assez d'options, en ajouter
        while (options.length < 4) {
          options.add('Option ${options.length + 1}');
        }

        // Limiter à 4 options
        if (options.length > 4) {
          options = options.sublist(0, 4);
        }

        // Corriger l'index si invalide
        int correctIndex = item['correct_index'] ?? 0;
        if (correctIndex < 0 || correctIndex >= options.length) {
          correctIndex = 0;
        }

        return QuizQuestion(
          question: item['question']?.toString() ?? 'Question non disponible',
          options: options,
          correctIndex: correctIndex,
          explanation: item['explanation']?.toString() ?? 'Pas d\'explication disponible',
        );
      }).toList();
    } catch (e) {
      print('❌ Parse error: $e');
      return [];
    }
  }

  // ─── Questions de secours ────────────────────────────────
  List<QuizQuestion> _getFallbackQuestions() {
    return [
      QuizQuestion(
        question: 'Qu\'est-ce que l\'intelligence artificielle ?',
        options: [
          'Une branche de l\'informatique',
          'Un type de matériel',
          'Un langage de programmation',
          'Un système d\'exploitation'
        ],
        correctIndex: 0,
        explanation: 'L\'IA est une branche de l\'informatique qui vise à créer des machines intelligentes.',
      ),
      QuizQuestion(
        question: 'Quel est le rôle principal d\'un algorithme ?',
        options: [
          'Stocker des données',
          'Résoudre un problème étape par étape',
          'Afficher des images',
          'Gérer la mémoire'
        ],
        correctIndex: 1,
        explanation: 'Un algorithme est une suite d\'instructions pour résoudre un problème.',
      ),
      QuizQuestion(
        question: 'Que signifie l\'acronyme API ?',
        options: [
          'Application Programming Interface',
          'Advanced Program Integration',
          'Automated Process Instruction',
          'Application Process Integration'
        ],
        correctIndex: 0,
        explanation: 'API signifie Application Programming Interface.',
      ),
      QuizQuestion(
        question: 'Qu\'est-ce que le Machine Learning ?',
        options: [
          'Un type de processeur',
          'Une méthode d\'apprentissage automatique',
          'Un langage de programmation',
          'Un système de fichiers'
        ],
        correctIndex: 1,
        explanation: 'Le Machine Learning permet aux machines d\'apprendre à partir de données.',
      ),
      QuizQuestion(
        question: 'Quel est le rôle d\'une base de données ?',
        options: [
          'Exécuter des programmes',
          'Stocker et organiser des données',
          'Afficher des pages web',
          'Gérer le réseau'
        ],
        correctIndex: 1,
        explanation: 'Une base de données stocke et organise les données de manière structurée.',
      ),
      QuizQuestion(
        question: 'Que signifie HTML ?',
        options: [
          'HyperText Markup Language',
          'High Technical Modern Language',
          'Hyper Transfer Media Language',
          'Home Tool Markup Language'
        ],
        correctIndex: 0,
        explanation: 'HTML signifie HyperText Markup Language.',
      ),
      QuizQuestion(
        question: 'Qu\'est-ce qu\'un framework ?',
        options: [
          'Un ensemble d\'outils pour développer',
          'Un type de base de données',
          'Un langage de programmation',
          'Un système d\'exploitation'
        ],
        correctIndex: 0,
        explanation: 'Un framework est un ensemble d\'outils et de bibliothèques pour faciliter le développement.',
      ),
      QuizQuestion(
        question: 'Que signifie l\'acronyme URL ?',
        options: [
          'Uniform Resource Locator',
          'Universal Reference Link',
          'United Resource Language',
          'User Request Location'
        ],
        correctIndex: 0,
        explanation: 'URL signifie Uniform Resource Locator.',
      ),
      QuizQuestion(
        question: 'Qu\'est-ce que le Cloud Computing ?',
        options: [
          'L\'utilisation de serveurs distants',
          'Un type d\'ordinateur',
          'Un logiciel de traitement de texte',
          'Un langage de programmation'
        ],
        correctIndex: 0,
        explanation: 'Le Cloud Computing permet d\'utiliser des ressources informatiques à distance via Internet.',
      ),
      QuizQuestion(
        question: 'Quel est le rôle d\'un pare-feu (firewall) ?',
        options: [
          'Protéger le réseau',
          'Accélérer la connexion',
          'Stocker des fichiers',
          'Afficher des pages web'
        ],
        correctIndex: 0,
        explanation: 'Un pare-feu protège le réseau en filtrant le trafic entrant et sortant.',
      ),
    ];
  }

  // ─── Parser la réponse JSON pour le résumé ─────────────
  Map<String, dynamic> _parseJSONResponse(String text) {
    try {
      final jsonStr = _extractJSON(text);
      final json = jsonDecode(jsonStr);

      return {
        'executiveSummary': json['executive_summary']?.toString() ?? 'Résumé généré avec succès.',
        'keyPoints': json['key_points'] is List ? List<String>.from(json['key_points']) : ['Information du document'],
        'definitions': json['definitions'] is Map ? Map<String, String>.from(json['definitions']) : {},
        'examTips': json['exam_tips'] is List ? List<String>.from(json['exam_tips']) : ['Relisez le document'],
        'difficultyLevel': json['difficulty_level']?.toString() ?? 'Moyen',
      };
    } catch (e) {
      return {
        'executiveSummary': text.length > 500 ? text.substring(0, 500) + '...' : text,
        'keyPoints': ['Information extraite du document'],
        'definitions': {},
        'examTips': ['Consultez le document original'],
        'difficultyLevel': 'Moyen',
      };
    }
  }

  // ─── Extraire le JSON d'une réponse ─────────────────────
  String _extractJSON(String text) {
    String cleaned = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final startIndex = cleaned.indexOf(RegExp(r'[\[\{]'));
    final endIndex = cleaned.lastIndexOf(RegExp(r'[\]\}]'));

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      return cleaned.substring(startIndex, endIndex + 1);
    }

    return cleaned;
  }

  // ─── Résumé par défaut ──────────────────────────────────
  Map<String, dynamic> _getDefaultSummary(String reason) {
    return {
      'executiveSummary': 'Le résumé n\'a pas pu être généré. $reason',
      'keyPoints': ['Service momentanément indisponible'],
      'definitions': {},
      'examTips': ['Vérifiez votre connexion internet et réessayez'],
      'difficultyLevel': 'N/A',
    };
  }
}