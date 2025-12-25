import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skillbox/models/chat.dart';
import 'package:skillbox/providers/user_provider.dart';
import '../../services/chat_service.dart';
import '../../services/pusher_service.dart';
import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final PusherService _pusherService = PusherService();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  File? _selectedFile;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _loadCurrentUserId();
    await _loadMessages();
    await _setupRealtimeChat();
  }

  Future<void> _loadCurrentUserId() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.isLoggedIn && userProvider.user != null) {
      setState(() {
        _currentUserId = userProvider.user!.id;
      });
      print('Current user ID from provider: $_currentUserId');
    } else {
      // Handle the case where user is not logged in
      print('No user is logged in.');
      _currentUserId = null;
    }
  }

  /// 🔥 Setup real-time chat listener
  Future<void> _setupRealtimeChat() async {
    try {
      // Initialize Pusher if not already done
      await _pusherService.initialize();

      // Subscribe to this specific chat channel
      await _pusherService.subscribeToChatChannel(
        _currentUserId ?? 0,
        widget.otherUserId,
      );

      // Listen for incoming messages
      _pusherService.onMessageReceived = (ChatMessage message) {
        print("💬 Real-time message in ChatScreen: ${message.text}");

        // Only add if message is not from current user (avoid duplicates)
        // and if message doesn't already exist
        if (message.senderId != _currentUserId) {
          setState(() {
            // Check if message already exists
            bool exists = _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
              _scrollToBottom();
            }
          });

          // Mark as read since user is viewing the chat
          ChatService.markAsRead(widget.conversationId);
        }
      };

      print("✅ Real-time chat setup complete");
    } catch (e) {
      print("❌ Error setting up real-time chat: $e");
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);

      final messages = await ChatService.getMessages(widget.conversationId);

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Mark as read
      await ChatService.markAsRead(widget.conversationId);

      // Scroll to bottom AFTER the frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty && _selectedFile == null) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        text: text.isNotEmpty ? text : null,
        attachmentFile: _selectedFile,
      );

      setState(() {
        // Add message immediately (optimistic update)
        _messages.add(message);
        _messageController.clear();
        _selectedFile = null;
        _isSending = false;
      });

      // Scroll to bottom (which is position 0 with reverse: true)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    // With reverse: true, position 0 is the bottom
    if (_scrollController.hasClients && mounted) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Clear the message callback when leaving
    _pusherService.onMessageReceived = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.otherUserName.isNotEmpty
        ? widget.otherUserName[0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.cyan[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages List
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true, // 👈 ADD THIS
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      // 👇 REVERSE THE INDEX
                      final reversedIndex = _messages.length - 1 - index;
                      final message = _messages[reversedIndex];
                      final isMine = message.senderId == _currentUserId;
                      return _buildMessageBubble(message, isMine);
                    },
                  ),
          ),

          // Selected File Preview
          if (_selectedFile != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedFile!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFile!.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _selectedFile = null);
                    },
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _showImageSourceDialog,
                    color: Colors.grey[600],
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.cyan,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine ? Colors.cyan : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasAttachment) ...[
                    if (message.isImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '${ApiService.baseUrl}/${message.attachmentPath}',
                          width: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 48),
                            );
                          },
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            color: isMine ? Colors.white : Colors.grey[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.attachmentPath?.split('/').last ?? 'File',
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black87,
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (message.text != null && message.text!.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  if (message.text != null && message.text!.isNotEmpty)
                    Text(
                      message.text!,
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.sendAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.isReaded ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.isReaded ? Colors.blue : Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
