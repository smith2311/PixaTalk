import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/apis.dart';
import '../models/chat_user_card.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';
import '../screens/view_profile_screen.dart';

/// Chat Screen where users send and receive messages
class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showEmojiPicker = false;
  bool _isUploadingImage = false;
  String _lastActiveStatus = 'Loading...';
  StreamSubscription? _userInfoSub;

  @override
  void initState() {
    super.initState();
    _listenToUserStatus();
    APIs.updateActiveStatus(true);
  }

  @override
  void dispose() {
    _userInfoSub?.cancel();
    APIs.updateActiveStatus(false);
    _textController.dispose();
    super.dispose();
  }

  /// Listens for user activity and updates UI accordingly
  void _listenToUserStatus() {
    _userInfoSub = APIs.getUserInfo(widget.user).listen((snapshot) {
      final data = snapshot.docs;
      if (data.isNotEmpty) {
        final userMap = data.first.data();
        final isOnline = userMap['is_online'] ?? false;
        final lastActive = userMap['last_active'] ?? '';

        setState(() {
          _lastActiveStatus =
          isOnline ? 'Online' : 'Last active: ${_formatTimestamp(lastActive)}';
        });
      }
    });
  }

  /// Converts timestamp to human-readable HH:MM format
  String _formatTimestamp(String timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Toggles emoji picker visibility
  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  /// Appends selected emoji to the text input field
  void onEmojiSelected(Emoji emoji) {
    _textController.text += emoji.emoji;
  }

  /// Sends a text message to Firestore
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await APIs.sendMessage(widget.user, text, Type.text);
    _textController.clear();
  }

  /// Picks an image from the specified source (gallery or camera)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      _uploadImage(pickedFile);
    }
  }

  /// Simulated image upload with UI updates
  Future<void> _uploadImage(XFile pickedFile) async {
    setState(() {
      _isUploadingImage = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isUploadingImage = false;
    });

    //log("Uploaded Image: ${pickedFile.path}");

  }

  /// Navigates to the profile screen when tapped
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewProfileScreen(user: widget.user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: InkWell(
            onTap: _navigateToProfile,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(widget.user.image),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    Text(
                      _lastActiveStatus,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: APIs.getMessagesStream(widget.user.id),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs.map((doc) {
                    final message = Message.fromJson(doc.data() as Map<String, dynamic>);
                    return MessageCard(message: message);
                  }).toList();

                  return ListView(reverse: true, children: messages);
                },
              ),
            ),
            _buildInputField(mq),
          ],
        ),
      ),
    );
  }

  /// Builds the bottom message input field
  Widget _buildInputField(Size mq) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _toggleEmojiPicker,
                          icon: const Icon(Icons.emoji_emotions, color: Colors.orange),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        _isUploadingImage
                            ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Row(
                          children: [
                            IconButton(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, color: Colors.red),
                            ),
                            IconButton(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.image, color: Colors.blue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MaterialButton(
                    onPressed: _sendMessage,
                    color: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minWidth: 0,
                    padding: const EdgeInsets.all(13),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          // Emoji Picker - Appears when _showEmojiPicker is true
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showEmojiPicker ? mq.height * 0.28 : 0,
            child: _showEmojiPicker
                ? EmojiPicker(
              config: Config(),
              onEmojiSelected: (category, emoji) {
                _textController.text += emoji.emoji; // Directly append emoji here
              },
            )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}