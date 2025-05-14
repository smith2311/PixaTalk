import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:frontend/models/chat_user_card.dart';
import 'package:frontend/models/message.dart';

class APIs {
  // Firebase instances
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;

  // Current user info
  static late ChatUser me;

  static User get user => auth.currentUser!;

  /// Check if user exists
  static Future<bool> userExist() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  /// Get self user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((userDoc) async {
      if (userDoc.exists) {
        me = ChatUser.fromJson(userDoc.data()!);
        log('Me: ${userDoc.data()}');
      } else {
        await createUser();
        await getSelfInfo();
      }
    });
  }

  /// Create new user in Firestore
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      about: "Hey, Can we have a Conversation",
      image: user.photoURL ?? '',
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: "",
    );
    await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
  }

  /// Get all users except current user
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  /// Update user name and about
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  /// Upload and update profile picture
  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log('Extension: $ext');
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((taskSnapshot) {
      log('Data Transferred: ${taskSnapshot.bytesTransferred / 1000} kb');
    });
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({'image': me.image});
  }

  /// Generate conversation ID
  static String getConversationId(String id) {
    return user.uid.hashCode <= id.hashCode
        ? '${user.uid}_$id'
        : '${id}_${user.uid}';
  }

  /// Get all messages from a conversation (ordered oldest to newest)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String userId) {
    final conversationId = getConversationId(userId);
    return firestore
        .collection('chats/$conversationId/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }


  /// Send message
  static Future<void> sendMessage(ChatUser toUser, String msg,Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final message = Message(
      msg: msg,
      read: '',
      told: toUser.id,
      type: type,
      sent: time,
      fromId: user.uid,
    );

    final ref = firestore.collection('chats/${getConversationId(toUser.id)}/messages/');
    await ref.doc(time).set(message.toJson());
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    firestore.collection('chats/${getConversationId(message.fromId)}/messages/').doc(message.sent)
        .update({'read':DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot> getLastMessage(ChatUser user){
    return firestore.collection('chats/${getConversationId(user.id)}/messages/')
        .orderBy('sent',descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser user,File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${getConversationId(user.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((taskSnapshot) {
      log('Data Transferred: ${taskSnapshot.bytesTransferred / 1000} kb');
    });
    final imageURL = await ref.getDownloadURL();
    await sendMessage(user, imageURL,Type.image);
  }

  static Stream<QuerySnapshot<Map<String,dynamic>>> getUserInfo(ChatUser chatUser){
    return firestore
        .collection('users')
        .where('id', isEqualTo:chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline)async{
    firestore.collection('users').doc(user.uid).update({
      'is_online':isOnline,
      'last_active':DateTime.now().millisecondsSinceEpoch.toString(),
    });
  }

  static Stream<QuerySnapshot> getAllMessages(ChatUser user) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(user.id)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}