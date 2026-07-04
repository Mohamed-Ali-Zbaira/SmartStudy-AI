import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import '../models/course_model.dart';
import '../services/groq_service.dart';

// ════════════════════════════════════════════════════════════
//  COULEURS
// ════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF1E3A5F);
  static const secondary = Color(0xFF4A90D9);
  static const success = Color(0xFF27AE60);
  static const danger = Color(0xFFE05050);
  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE0EAF5);
  static const textPrimary = Color(0xFF1E3A5F);
  static const textSecondary = Color(0xFF6B8BA4);
  static const textHint = Color(0xFF94AFC6);
}

// ════════════════════════════════════════════════════════════
//  MODÈLES
// ════════════════════════════════════════════════════════════
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime time;
  bool isLoading;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.time,
    this.isLoading = false,
  });
}

// ════════════════════════════════════════════════════════════
//  CHAT SCREEN
// ════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  final CourseModel course;

  const ChatScreen({super.key, required this.course});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _groqService = GroqService();

  // ✅ Speech-to-Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  bool _isTyping = false;

  final List<String> _suggestions = [
    'Expliquer plus simplement',
    'Donne-moi un exemple concret',
    'Résume ce concept en 3 points',
    'Quels sont les points importants ?',
    'Différence entre les concepts clés',
  ];

  late List<ChatMessage> _messages;
  List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        text: 'Bonjour ! 👋 Je suis votre assistant IA pour le cours **${widget.course.title}**. Posez-moi n\'importe quelle question et je vous répondrai avec précision en me basant sur le contenu du document.',
        sender: MessageSender.ai,
        time: DateTime.now(),
      ),
    ];
    _initSpeech();
  }

  // ✅ Initialiser la reconnaissance vocale
  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onStatus: (status) {
        print('🎤 Speech status: $status');
        if (status == 'notListening' || status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('🎤 Speech error: $error');
        setState(() => _isListening = false);
      },
    );
    setState(() {});
  }

  // ✅ Démarrer/Arrêter l'écoute
  void _toggleListening() async {
    if (_isListening) {
      // Arrêter l'écoute
      await _speech.stop();
      setState(() {
        _isListening = false;
        if (_lastWords.isNotEmpty) {
          _inputController.text = _lastWords;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        }
      });
    } else {
      // Démarrer l'écoute
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _inputController.text = _lastWords;
            _inputController.selection = TextSelection.fromPosition(
              TextPosition(offset: _inputController.text.length),
            );
          });
        },
        localeId: 'fr_FR', // Français
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
      setState(() => _isListening = true);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isTyping) return;

    final question = text.trim();

    final userMsg = ChatMessage(
      text: question,
      sender: MessageSender.user,
      time: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      text: '',
      sender: MessageSender.ai,
      time: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _inputController.clear();
      _lastWords = '';
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _groqService.chatWithDocument(
        widget.course.pdfText,
        question,
        history: _chatHistory,
      );

      _chatHistory.add({'role': 'user', 'content': question});
      _chatHistory.add({'role': 'assistant', 'content': response});

      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(
            text: response,
            sender: MessageSender.ai,
            time: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(
            text: 'Désolé, une erreur est survenue. Veuillez réessayer.',
            sender: MessageSender.ai,
            time: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Effacer la conversation',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        content: const Text('Cette action supprimera tout l\'historique.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _chatHistory.clear();
                _messages.add(ChatMessage(
                  text: 'Conversation réinitialisée. Comment puis-je vous aider ?',
                  sender: MessageSender.ai,
                  time: DateTime.now(),
                ));
              });
            },
            child: const Text('Effacer', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  String get _courseEmoji {
    final s = widget.course.subject.toLowerCase();
    if (s.contains('base') || s.contains('donnée')) return '📊';
    if (s.contains('algo') || s.contains('program')) return '🧮';
    if (s.contains('réseau')) return '🌐';
    if (s.contains('système')) return '🖥️';
    return '📄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              courseTitle: widget.course.title,
              courseEmoji: _courseEmoji,
              onBack: () => Navigator.pop(context),
              onClear: _clearChat,
            ),
            _SuggestionsRow(suggestions: _suggestions, onTap: _sendMessage),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
              ),
            ),
            _InputBar(
              controller: _inputController,
              isTyping: _isTyping,
              isListening: _isListening,
              speechEnabled: _speechEnabled,
              onSend: () => _sendMessage(_inputController.text),
              onToggleMic: _toggleListening,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  HEADER
// ────────────────────────────────────────────────────────────
class _ChatHeader extends StatelessWidget {
  final String courseTitle;
  final String courseEmoji;
  final VoidCallback onBack;
  final VoidCallback onClear;

  const _ChatHeader({required this.courseTitle, required this.courseEmoji, required this.onBack, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2A5482)]),
      ),
      padding: const EdgeInsets.fromLTRB(4, 10, 10, 12),
      child: Row(
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18)),
          Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 17)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat IA — $courseTitle', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('En ligne', style: TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: onClear, icon: const Icon(Icons.delete_outline, color: Colors.white60, size: 20), tooltip: 'Effacer'),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  SUGGESTIONS ROW - CORRIGÉ 👍
// ────────────────────────────────────────────────────────────
class _SuggestionsRow extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionsRow({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: () => onTap(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEDF4FD), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFB5D4F4))),
                child: Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF185FA5), fontWeight: FontWeight.w500)),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  MESSAGE BUBBLE
// ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});
  bool get _isUser => message.sender == MessageSender.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle), child: const Center(child: Text('🤖', style: TextStyle(fontSize: 13)))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isUser ? AppColors.secondary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14), topRight: const Radius.circular(14),
                  bottomLeft: _isUser ? const Radius.circular(14) : const Radius.circular(3),
                  bottomRight: _isUser ? const Radius.circular(3) : const Radius.circular(14),
                ),
                border: _isUser ? null : Border.all(color: AppColors.border),
              ),
              child: message.isLoading
                  ? const _TypingIndicator()
                  : Text(message.text, style: TextStyle(fontSize: 13, color: _isUser ? Colors.white : AppColors.textPrimary, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  TYPING INDICATOR - CORRIGÉ 🎨
// ────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    ));

    _animations = List.generate(3, (i) => Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeInOut,
      ),
    ));

    // Démarrer les animations avec décalage
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                // ✅ CORRECTION: Utilisation de withValues au lieu de withOpacity
                color: AppColors.textHint.withValues(alpha: 0.3 + (_animations[i].value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  INPUT BAR (avec micro) - CORRIGÉ 🎤
// ────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final bool isListening;
  final bool speechEnabled;
  final VoidCallback onSend;
  final VoidCallback onToggleMic;

  const _InputBar({
    required this.controller,
    required this.isTyping,
    required this.isListening,
    required this.speechEnabled,
    required this.onSend,
    required this.onToggleMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          // ✅ Bouton Microphone
          if (speechEnabled)
            GestureDetector(
              onTap: onToggleMic,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isListening ? AppColors.danger : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: isListening ? AppColors.danger : AppColors.border),
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_outlined,
                  color: isListening ? Colors.white : AppColors.textHint,
                  size: 20,
                ),
              ),
            ),
          if (speechEnabled) const SizedBox(width: 6),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isListening ? const Color(0xFFFFF0F0) : AppColors.background,
                borderRadius: BorderRadius.circular(24),
                // ✅ CORRECTION: Utilisation de withValues au lieu de withOpacity
                border: Border.all(color: isListening ? AppColors.danger.withValues(alpha: 0.3) : AppColors.border),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3, minLines: 1,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: isListening ? '🎤 Écoute en cours...' : 'Poser une question ou utiliser le micro...',
                  hintStyle: TextStyle(fontSize: 13, color: isListening ? AppColors.danger : AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isTyping ? null : onSend,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: isTyping ? AppColors.textHint : AppColors.secondary, shape: BoxShape.circle),
              child: isTyping
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}