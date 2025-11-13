import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/helper/my_date_util.dart';
import 'package:frontend/models/message.dart';
import 'package:frontend/widgets/dialogs/profile_dialog.dart';
import '../api/apis.dart';
import '../main.dart';
import '../models/chat_user_card.dart';
import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {

  Message ? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            // Handle stream connection state, data, or error here if needed
            final data = snapshot.data?.docs;
            final list = data?.map((e) => Message.fromJson(e.data() as Map<String, dynamic>)).toList() ?? [];
            if(list.isNotEmpty){
              _message= list[0];
            }
            return ListTile(
              leading: InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_)=> ProfileDialog(user: widget.user));
                },

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) =>
                    const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
              ),
              title: Text(widget.user.name),
              subtitle: Text(
                  _message != null ?
                  _message!.type == Type.image ? 'Image' :
                  _message!.msg : widget.user.about,
                  maxLines: 1),

              //LAST MESSAGE TIME
              trailing: _message == null ? null :
                  _message!.read.isEmpty && _message!.fromId != APIs.user.uid ?
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ) : Text(MyDateUtil.getLastMessageTime(context: context,time: _message!.sent),
                      style: TextStyle(color: Colors.black54))
            );
          },
        ),
      ),
    );
  }
}
