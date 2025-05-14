import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/view_profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../api/apis.dart';
import '../models/chat_user_card.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showEmoji = false;
  bool _isUploading = false;
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

  // Listen to user status and update UI accordingly
  void _listenToUserStatus() {
    _userInfoSub = APIs.getUserInfo(widget.user).listen((snapshot) {
      final data = snapshot.docs;
      if (data.isNotEmpty) {
        final userMap = data.first.data();
        final isOnline = userMap['is_online'] ?? false;
        final lastActive = userMap['last_active'] ?? '';

        setState(() {
          _lastActiveStatus = isOnline
              ? 'Online'
              : 'Last active: ${_formatTimestamp(lastActive)}';
        });
      }
    });
  }

  // Format timestamp into readable time
  String _formatTimestamp(String timestamp) {
    final time = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Toggle emoji picker visibility
  void _toggleEmojiPicker() {
    setState(() {
      _showEmoji = !_showEmoji;
    });
  }

  // Emoji selection handler
  void _onEmojiSelected(Emoji emoji) {
    _textController.text += emoji.emoji;
  }

  // Send message function
  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    await APIs.sendMessage(widget.user, text, Type.text);
    _textController.clear();
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _uploadImage(pickedFile);
    }
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _uploadImage(pickedFile);
    }
  }

  // Upload image function with progress bar
  Future<void> _uploadImage(XFile pickedFile) async {
    setState(() {
      _isUploading = true;
    });

    // Simulate uploading the image
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isUploading = false;
    });
    print("Uploaded Image: ${pickedFile.path}");
  }

  // Navigate to ViewProfileScreen when tapping the AppBar
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) =>  ViewProfileScreen(user:widget.user)),
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
                    Text(widget.user.name,
                        style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    Text(_lastActiveStatus,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
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

                  return ListView(
                    reverse: true,
                    children: messages,
                  );
                },
              ),
            ),
            _buildInputField(mq),
          ],
        ),
      ),
    );
  }

  // Text Input field and action buttons
  Widget _buildInputField(Size mq) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: _showEmoji ? mq.height * 0.28 : 25,
        left: 10,
        right: 10,
      ),
      child: Row(
        children: [
          // Emoji Picker Button
          IconButton(
            onPressed: _toggleEmojiPicker,
            color: Colors.orange,
            icon: const Icon(Icons.emoji_emotions),
          ),

          // Text Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Camera and Gallery buttons
                  IconButton(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    color: Colors.red,
                  ),
                  IconButton(
                    color: Colors.blue,
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.image),
                  ),
                ],
              ),
            ),
          ),

          // Send Button (Smaller size)
          MaterialButton(
            onPressed: _sendMessage,
            color: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            minWidth: 0,
            padding: const EdgeInsets.all(13),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

