import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, audio, file, gift }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  final String? replyToId;
  final String? replyToText;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.text,
    this.mediaUrl,
    this.fileName,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.replyToId,
    this.replyToText,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      fileName: data['fileName'],
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
    );
  }
}

class ChatModel {
  final String id;
  final List<String> members;
  final Map<String, String> memberNames;
  final Map<String, String?> memberAvatars;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final MessageType? lastMessageType;
  final Map<String, int> unreadCount;

  const ChatModel({
    required this.id,
    required this.members,
    required this.memberNames,
    required this.memberAvatars,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastMessageType,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      members: List<String>.from(data['members'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      memberAvatars: Map<String, String?>.from(data['memberAvatars'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageType: data['lastMessageType'] != null
          ? MessageType.values.firstWhere(
              (e) => e.name == data['lastMessageType'],
              orElse: () => MessageType.text)
          : null,
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }
}
