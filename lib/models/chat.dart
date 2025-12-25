class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? text;
  final String? attachmentPath;
  final DateTime sendAt;
  final bool isReaded;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.text,
    this.attachmentPath,
    required this.sendAt,
    this.isReaded = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      text: json['text'] as String?,
      attachmentPath: json['attachment_path'] as String?,
      sendAt: DateTime.parse(json['send_at']),
      isReaded: json['is_readed'] == 1, // or as needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'attachment_path': attachmentPath,
      'send_at': sendAt.toIso8601String(),
      'is_readed': isReaded ? 1 : 0,
    };
  }

  bool get hasAttachment =>
      attachmentPath != null && attachmentPath!.isNotEmpty;

  bool get isImage {
    if (!hasAttachment) return false;
    final ext = attachmentPath!.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }
}
