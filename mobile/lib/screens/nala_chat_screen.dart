import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class NalaChatScreen extends StatefulWidget {
  const NalaChatScreen({super.key});

  @override
  State<NalaChatScreen> createState() => _NalaChatScreenState();
}

class _NalaChatScreenState extends State<NalaChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
        text:
            'Hei! Aku Nala, asisten keuangan pribadimu. Ada yang bisa aku bantu seputar keuanganmu bulan ini?',
        isUser: false),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

  Future<void> _sendMessage() async {
    if (_isLoading) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    final response = await _chatService.sendMessage(text);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response != null) {
          _messages.add(ChatMessage(text: response.message, isUser: false));
        } else {
          _messages.add(ChatMessage(
              text: 'Maaf, koneksi Nala terputus. Coba lagi nanti ya!',
              isUser: false));
        }
      });
      _scrollToBottom();

      final draft = response?.transactionDraft;
      if (draft != null) {
        final saved = await Navigator.push<bool>(
          context,
          addTransactionRoute(transactionDraft: draft),
        );
        if (!mounted) return;
        setState(() {
          _messages.add(
            ChatMessage(
              text: saved == true
                  ? 'Transaksinya sudah tersimpan setelah kamu konfirmasi.'
                  : 'Draft belum disimpan. Kamu tetap memegang kendali.',
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                final msg = _messages[index];
                if (msg.isUser) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildUserMessage(msg.text),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildNalaMessage(msg.text, showAvatar: true),
                  );
                }
              },
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF45B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.textPrimary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nala',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'Asisten finansial • AI',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF45B),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppTheme.textPrimary,
            size: 15,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEDF2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 9),
              Text(
                'Nala sedang menyusun...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNalaMessage(String text, {bool showAvatar = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar)
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF45B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.textPrimary,
              size: 15,
            ),
          )
        else
          const SizedBox(width: 38),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEAEDF2)),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 38),
      ],
    );
  }

  Widget _buildUserMessage(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(width: 42),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9630),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEAEDF2))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_messages.length == 1 && !_isLoading) ...[
              _buildQuickPrompts(),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEAEDF2)),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tanya Nala...',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    const prompts = [
      'Ringkas pengeluaranku',
      'Bantu atur budget',
      'Catat transaksi',
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ActionChip(
          label: Text(
            prompts[index],
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          onPressed: () {
            _textController.text = prompts[index];
            _sendMessage();
          },
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFEAEDF2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }
}
