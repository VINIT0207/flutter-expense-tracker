import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../viewmodels/main_viewmodel.dart';
import '../logic/slm_controller.dart';
import '../services/local_ai_service.dart';
import '../services/model_setup_service.dart';
import '../data/finance_repository.dart';

const Color kPrimaryColor = Color(0xFF818CF8);
const Color kBackgroundColor = Color(0xFF080C14);
const Color kSurfaceColor = Color(0xFF151D2C);

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  SlmController? _slmController;
  bool _hasStartedInit = false;
  bool _isInitializing = false;
  bool _isEngineReady = false;
  bool _isThinking = false;

  final List<String> _quickPrompts = [
    "How can I save more this month?",
    "Review my spending patterns",
    "What's my biggest expense category?",
    "Tips to reduce optional expenses",
  ];

  @override
  void initState() {
    super.initState();
    // Initial greeting
    _messages.add(
      ChatMessage(
        text: "👋 Hi! I'm your local AI financial assistant. I analyze your budget and spending patterns 100% offline. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure AI initializes exactly ONCE and is not destroyed when keyboard opens
    if (!_hasStartedInit) {
      _hasStartedInit = true;
      _isInitializing = true;
      final repo = Provider.of<FinanceRepository>(context, listen: false);
      _slmController = SlmController(LocalAiService(), repo);
      _initializeAI();
    }
  }

  Future<void> _initializeAI() async {
    final modelPath = await ModelSetupService.prepareModelFile();

    if (modelPath != null && _slmController != null) {
      final success = await _slmController!.aiService.initialize(modelPath);
      if (mounted) {
        setState(() {
          _isEngineReady = success;
          _isInitializing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _slmController?.aiService.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty || _isThinking || _slmController == null) return;

    final controller = _slmController!;
    final promptText = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: promptText,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isThinking = true;
    });

    _scrollToBottom();

    final viewModel = Provider.of<MainViewModel>(context, listen: false);
    final monthlyBudget = viewModel.monthlyBudget;

    Future.microtask(() async {
      try {
        final response =
            await controller.processUserMessage(promptText, monthlyBudget);

        if (!mounted) return;
        setState(() {
          _isThinking = false;
          _messages.add(
            ChatMessage(
              text: response.reply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      } catch (e) {
        debugPrint("AI Chat Processing Error: $e");
        if (!mounted) return;
        setState(() {
          _isThinking = false;
          _messages.add(
            ChatMessage(
              text: "I encountered a brief processing hiccup. Please ask me again! 💡",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      } finally {
        if (mounted) {
          setState(() => _isThinking = false);
          _scrollToBottom();
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor.withAlpha(220),
        elevation: 8,
        shadowColor: Colors.black.withAlpha(140),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(35), width: 1.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: kPrimaryColor.withAlpha(51),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryColor.withAlpha(120), width: 1),
              ),
              child: const Icon(Icons.auto_awesome, color: kPrimaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "AI Financial Advisor",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isEngineReady
                        ? "Active • On-Device AI"
                        : (_isInitializing ? "Initializing Engine..." : "Offline Ready"),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isEngineReady
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFBBF24),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isThinking) {
                  return const _ThinkingBubble();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isEngineReady) _buildQuickPromptsBar(),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
            ),
            backgroundColor: kSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF334155), width: 1.2),
            ),
            onPressed: () => _handleSubmitted(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: kPrimaryColor.withAlpha(51),
                radius: 14,
                child: const Icon(Icons.auto_awesome,
                    size: 14, color: kPrimaryColor),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFF334155), width: 1.2),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        border: Border(top: BorderSide(color: Color(0xFF222F43), width: 1.0)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset > 0 ? 8.0 : MediaQuery.of(context).padding.bottom + 8.0,
        top: 8,
        left: 14,
        right: 10,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13.5),
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: "Ask about budget, spending, tips...",
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF0B101B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF222F43), width: 1.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF222F43), width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), kPrimaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(100),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: () => _handleSubmitted(_textController.text),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated Thinking Bubble with bouncing dots & pulsing glow
class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              backgroundColor: kPrimaryColor.withAlpha(51),
              radius: 14,
              child: const Icon(
                Icons.auto_awesome,
                size: 14,
                color: kPrimaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: kPrimaryColor.withAlpha(70)),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withAlpha(30),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ark is thinking",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value = ((_controller.value - delay) % 1.0);
                        final scale = (value < 0.5)
                            ? 0.4 + (value * 1.2)
                            : 1.0 - ((value - 0.5) * 1.2);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withAlpha(
                              ((0.3 + (scale * 0.7)).clamp(0.2, 1.0) * 255).toInt(),
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
