enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final bool isVoice;
  final DateTime timestamp;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.isVoice,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    bool? isVoice,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      isVoice: isVoice ?? this.isVoice,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}