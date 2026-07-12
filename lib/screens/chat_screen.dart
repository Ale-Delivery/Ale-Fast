import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_colors.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String orderName;

  const ChatScreen({super.key, required this.orderId, required this.orderName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String _userId = '';
  String _userName = 'You';
  late Stream<List<Map<String, dynamic>>> _msgStream;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _userId = await LocalStorageService.getUserId() ?? '';
    _userName = await LocalStorageService.getUserName() ?? 'You';

    _msgStream = Supabase.instance.client
        .from('Messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', widget.orderId)
        .order('created_at', ascending: true)
        .map((rows) => List<Map<String, dynamic>>.from(rows));

    if (!mounted) return;
    _msgStream.listen((msgs) {
      if (mounted) {
        setState(() => _messages = msgs);
        _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _userId.isEmpty) return;
    _msgController.clear();

    await Supabase.instance.client.from('Messages').insert({
      'order_id': widget.orderId,
      'sender_id': _userId,
      'sender_name': _userName,
      'message': text,
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              widget.orderName,
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, size: 6, color: AppColors.green),
                SizedBox(width: 4),
                Text('Online',
                    style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Driver info banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.bike, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        'Typically replies in a few minutes',
                        style: TextStyle(fontSize: 12, color: context.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(LucideIcons.phone, color: AppColors.accent, size: 20),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageCircle, size: 48, color: context.textHint),
                        const SizedBox(height: 12),
                        Text('No messages yet', style: TextStyle(color: context.textMuted)),
                        const SizedBox(height: 4),
                        Text('Send a message to your rider',
                            style: TextStyle(fontSize: 12, color: context.textHint)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg['sender_id'] == _userId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: context.cardBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.chipBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: context.textHint, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final time = msg['created_at'] != null
        ? DateFormat('HH:mm').format(DateTime.parse(msg['created_at'].toString()).toLocal())
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? AppGradients.primary : null,
          color: isMe ? null : context.cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: context.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg['message'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white.withValues(alpha: 0.7) : context.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
