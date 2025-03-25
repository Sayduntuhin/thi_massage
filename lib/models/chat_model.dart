// Data Models
class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final bool isVoice;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    this.isVoice = false,
    required this.timestamp,
  });
}