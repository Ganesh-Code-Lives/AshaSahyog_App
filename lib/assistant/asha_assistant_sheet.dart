import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/asha_assistant_provider.dart';
import 'asha_chat_message_bubble.dart';
import 'asha_quick_actions.dart';
import 'asha_typing_indicator.dart';
import 'models/chat_message.dart';

class AshaAssistantSheet extends StatefulWidget {
  final Function(String route) onNavigate;

  const AshaAssistantSheet({super.key, required this.onNavigate});

  @override
  State<AshaAssistantSheet> createState() => _AshaAssistantSheetState();
}

class _AshaAssistantSheetState extends State<AshaAssistantSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AshaAssistantProvider>();
      if (!provider.hasGreeted) {
        provider.setHasGreeted(true);
        provider.addAssistantMessage(
          ChatMessage(
            text: "Hello 👋\n\nI'm Asha, your personal AshaSahyog assistant.\n\nI can help you find government schemes, locate nearby healthcare services, manage reminders, or get emergency assistance.",
            isUser: false,
          ),
          speak: false,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          provider.addAssistantMessage(
            ChatMessage(
              text: "How can I help you today?",
              isUser: false,
            ),
            speak: true,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Because ListView is reversed
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    FocusScope.of(context).unfocus();
    
    context.read<AshaAssistantProvider>().addUserMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet handles the dragging and sizing
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.80, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Consumer<AshaAssistantProvider>(
                  builder: (context, provider, child) {
                    final messages = provider.messages.reversed.toList();
                    
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      reverse: true, // New messages at bottom
                      itemCount: messages.length + (provider.isTyping ? 1 : 0) + 1, // +1 for quick actions if needed
                      itemBuilder: (context, index) {
                        if (provider.isTyping && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: AshaTypingIndicator(),
                            ),
                          );
                        }
                        
                        final msgIndex = provider.isTyping ? index - 1 : index;
                        
                        // Show Quick Actions at the very top (end of reversed list) if it's the beginning of conversation
                        if (msgIndex == messages.length) {
                          if (messages.length <= 2) {
                             return AshaQuickActions(
                               onActionTap: _handleSend,
                             );
                          }
                          return const SizedBox.shrink();
                        }

                        final message = messages[msgIndex];
                        return AshaChatMessageBubble(
                          message: message,
                          onActionTap: message.actionRoute != null ? () {
                            Navigator.pop(context); // Close sheet
                            widget.onNavigate(message.actionRoute!);
                          } : null,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildComposer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: Transform.scale(
                  scale: 1.05,
                  child: Image.asset(
                    'assets/images/asha_assistant.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Asha",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "Your AshaSahyog Assistant",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Close Button
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Row(
        children: [
          // Mic Button
          GestureDetector(
            onTap: () {
              // TODO: Implement Speech-to-Text when available
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice input coming soon!')),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.purpleLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.mic_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          
          // Text Field
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Type your message...",
                hintStyle: const TextStyle(color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _handleSend,
            ),
          ),
          const SizedBox(width: 12),
          
          // Send Button
          GestureDetector(
            onTap: () => _handleSend(_textController.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
