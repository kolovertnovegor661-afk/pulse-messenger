import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/models/message_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId, recipientId, recipientName, recipientAvatar;
  const ChatDetailScreen({super.key, required this.chatId,
      required this.recipientId, required this.recipientName,
      required this.recipientAvatar});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _sending = false;
  MessageModel? _replyTo;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.collection('chats')
        .doc(widget.chatId).update({'unreadCount.$_uid': 0});
  }

  Future<void> _send({String? text, String? mediaUrl,
      String? fileName, MessageType type = MessageType.text}) async {
    if ((text == null || text.isEmpty) && mediaUrl == null) return;
    setState(() => _sending = true);
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    await chatRef.collection('messages').add({
      'senderId': _uid,
      'senderName': userData['displayName'] ?? '',
      'senderAvatar': userData['avatarUrl'],
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'type': type.name,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isDeleted': false,
      'replyToId': _replyTo?.id,
      'replyToText': _replyTo?.text,
    });
    await chatRef.update({
      'lastMessage': text ?? '📎 File',
      'lastMessageSenderId': _uid,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageType': type.name,
      'unreadCount.${widget.recipientId}': FieldValue.increment(1),
    });
    setState(() { _sending = false; _replyTo = null; });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients)
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final ref = FirebaseStorage.instance.ref()
        .child('chats/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(file.path));
    await _send(mediaUrl: await ref.getDownloadURL(), type: MessageType.image);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    final ref = FirebaseStorage.instance.ref()
        .child('chats/${widget.chatId}/${file.name}');
    await ref.putFile(File(file.path!));
    await _send(mediaUrl: await ref.getDownloadURL(),
        fileName: file.name, type: MessageType.file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          CircleAvatar(
            radius: 18, backgroundColor: AppColors.surfaceElevated,
            backgroundImage: widget.recipientAvatar.isNotEmpty
                ? CachedNetworkImageProvider(widget.recipientAvatar) : null,
            child: widget.recipientAvatar.isEmpty
                ? Text(widget.recipientName.isNotEmpty
                    ? widget.recipientName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.recipientName, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users')
                  .doc(widget.recipientId).snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final online = data?['isOnline'] ?? false;
                return Text(online ? 'online' : 'offline',
                    style: TextStyle(color: online ? AppColors.green : AppColors.textTertiary,
                        fontSize: 12));
              },
            ),
          ])),
        ]),
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('chats')
              .doc(widget.chatId).collection('messages')
              .orderBy('timestamp').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
            final msgs = snap.data!.docs.map((d) => MessageModel.fromFirestore(d)).toList();
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: msgs.length,
              itemBuilder: (context, i) {
                final msg = msgs[i];
                final isMe = msg.senderId == _uid;
                return GestureDetector(
                  onLongPress: () => setState(() => _replyTo = msg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 14, backgroundColor: AppColors.surfaceElevated,
                            backgroundImage: msg.senderAvatar != null
                                ? CachedNetworkImageProvider(msg.senderAvatar!) : null,
                            child: msg.senderAvatar == null
                                ? Text(msg.senderName.isNotEmpty
                                    ? msg.senderName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)) : null,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (msg.replyToText != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(msg.replyToText!,
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    overflow: TextOverflow.ellipsis, maxLines: 2),
                              ),
                            if (msg.type == MessageType.image && msg.mediaUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(imageUrl: msg.mediaUrl!,
                                    width: 220, fit: BoxFit.cover),
                              ),
                            if (msg.type == MessageType.file)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.insert_drive_file_outlined,
                                    color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Flexible(child: Text(msg.fileName ?? 'File',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis)),
                              ]),
                            if (msg.text != null && msg.text!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: msg.type != MessageType.text ? 6 : 0),
                                child: Text(msg.isDeleted ? 'Message deleted' : msg.text!,
                                    style: TextStyle(
                                      color: msg.isDeleted ? Colors.white54 : Colors.white,
                                      fontSize: 15,
                                      fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                                    )),
                              ),
                            const SizedBox(height: 4),
                            Text(timeago.format(msg.timestamp, locale: 'en_short'),
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                          ]),
                        )),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        )),
        if (_replyTo != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
            child: Row(children: [
              Container(width: 3, height: 36, color: AppColors.primary,
                  margin: const EdgeInsets.only(right: 10)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reply', style: TextStyle(color: AppColors.primary, fontSize: 12,
                    fontWeight: FontWeight.w600)),
                Text(_replyTo?.text ?? '', style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded,
                  color: AppColors.textTertiary, size: 18),
                  onPressed: () => setState(() => _replyTo = null)),
            ]),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: const BoxDecoration(color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
          child: SafeArea(child: Row(children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary, size: 22),
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _attach(ctx, Icons.image_outlined, 'Photo', AppColors.blue, _pickImage),
                    _attach(ctx, Icons.insert_drive_file_outlined, 'File', AppColors.green, _pickFile),
                  ]),
                ),
              ),
            ),
            Expanded(child: Container(
              decoration: BoxDecoration(color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border)),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                maxLines: 4, minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _send(text: _ctrl.text.trim()),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _sending ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: _sending
                    ? const Center(child: SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
    );
  }

  Widget _attach(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(ctx); onTap(); },
      child: Column(children: [
        Container(width: 56, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ]),
    );
  }
}
