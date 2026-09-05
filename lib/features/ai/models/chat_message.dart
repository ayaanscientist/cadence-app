import 'package:equatable/equatable.dart';

/// A single message in the Gemini AI chat conversation.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
  });

  /// Who sent this message.
  final ChatRole role;

  /// The text content of the message.
  final String content;

  /// When the message was created.
  final DateTime timestamp;

  /// True while waiting for the AI response.
  final bool isLoading;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
  bool get isSystem => role == ChatRole.system;

  @override
  List<Object?> get props => [role, content, timestamp, isLoading];
}

/// Chat participant roles.
enum ChatRole { user, assistant, system }
