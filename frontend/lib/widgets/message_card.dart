import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/helper/my_date_util.dart';
import 'package:frontend/models/message.dart';

import '../main.dart';

class MessageCard extends StatelessWidget {
  final Message message;

  const MessageCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isSender = APIs.user.uid == message.fromId;

    // Mark message as read if current user is receiver and message is unread
    if (!isSender && message.read.isEmpty) {
      APIs.updateMessageReadStatus(message);
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * 0.008,
        horizontal: mq.width * 0.04,
      ),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: isSender ? _buildSenderMessage(context) : _buildReceiverMessage(context),
      ),
    );
  }

  // Sender's message bubble (green)
  Widget _buildSenderMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(mq.width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF81C784).withOpacity(0.3),
        border: Border.all(color: const Color(0xFF388E3C)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: message.type == Type.image
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildMessageContent(),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                message.read.isNotEmpty
                    ? Icons.done_all_rounded
                    : Icons.done_rounded,
                size: 18,
                color: message.read.isNotEmpty ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                MyDateUtil.getFormattedTime(
                  context: context,
                  time: message.sent.toString(),
                ),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Receiver's message bubble (blue)
  Widget _buildReceiverMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(mq.width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF8F76FF).withOpacity(0.3),
        border: Border.all(color: const Color(0xFF6F4DCC)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: message.type == Type.image
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildMessageContent(),
          ),
          const SizedBox(height: 6),
          Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: message.sent.toString(),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Handles both text and image messages
  Widget _buildMessageContent() {
    if (message.type == Type.text) {
      return Text(
        message.msg,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: message.msg,
          fit: BoxFit.cover,
          width: mq.width * 0.5,
          placeholder: (context, url) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image, size: 70),
        ),
      );
    }
  }
}
