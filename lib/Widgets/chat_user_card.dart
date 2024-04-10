import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xpress/Widgets/dialogs/profile_dialog.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/helper/my_date_util.dart';
import 'package:xpress/main.dart';
import 'package:xpress/models/chat_user.dart';
import 'package:xpress/models/message.dart';
import 'package:xpress/screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({Key? key, required this.user}) : super(key: key);

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
// last message info
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * 0.04, vertical: 4),
      color: Color.fromARGB(255, 33, 33, 33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
          onTap: () {
            // for navigating to chat screen
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          user: widget.user,
                        )));
          },
          child: StreamBuilder(
            stream: APIs.getLastMessage(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
              if (list.isNotEmpty) _message = list[0];

              return ListTile(
                // leading: CircleAvatar(
                //   child: Icon(CupertinoIcons.person),
                // ),
                // user profile picture
                leading: InkWell(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => ProfileDialog(
                              user: widget.user,
                            ));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      width: mq.height * .055,
                      height: mq.height * .055,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) => CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                    ),
                  ),
                ),

                // username
                title: Text(
                  widget.user.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),

                //last message
                subtitle: Text(
                  _message != null
                      ? _message!.type == Type.image
                          ? 'Image 🏞️'
                          : _message!.msg
                      : widget.user.about,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                ),

                //last message time
                trailing: _message == null
                    ? null
                    : _message!.read.isEmpty &&
                            _message!.fromId != APIs.user.uid
                        // show for unread message
                        ? Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 255, 255, 255),
                                borderRadius: BorderRadius.circular(7)),
                          )
                        : Text(
                            MyDateUtil.getLastMessageTime(
                                context: context, time: _message!.sent),
                            style: TextStyle(color: Colors.grey),
                          ),
              );
            },
          )),
    );
  }
}
