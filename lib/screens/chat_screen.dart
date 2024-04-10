import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xpress/helper/my_date_util.dart';

import 'package:xpress/main.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/screens/view_profile_screens.dart';

import '../models/chat_user.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // for storing all messages
  List<Message> _list = [];

  // for handling message text changes
  final _textController = TextEditingController();

  // for storing value of showing or hiding emoji
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            //app bar
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),
            //body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return SizedBox();

                        // if data is loaded
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(
                                    message: _list[index],
                                  );
                                });
                          } else {
                            return Center(
                              child: Text(
                                'Say Hi! 👋',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 85, 85, 85),
                                  fontSize: 20,
                                ),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),

                // progress indicator for showing uploading
                if (_isUploading)
                  Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))),

                // chat input field
                _chatInput(),

                // show emojis on keyboard
                // Comment out the emoji button and its functionalities
                // if (_showEmoji)
                //   SizedBox(
                //     height: mq.height * .35,
                //     child: EmojiPicker(
                //       textEditingController:
                //           _textController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                //       config: Config(
                //         height: 256,
                //         checkPlatformCompatibility: true,
                //         emojiViewConfig: EmojiViewConfig(
                //           emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                //         ),
                //         swapCategoryAndBottomBar: false,
                //         skinToneConfig: const SkinToneConfig(),
                //         categoryViewConfig: const CategoryViewConfig(),
                //         bottomActionBarConfig: const BottomActionBarConfig(),
                //         searchViewConfig: const SearchViewConfig(),
                //       ),
                //     ),
                //   )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // app bar widget
  Widget _appBar() {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(user: widget.user)));
        },
        child: StreamBuilder(
            stream: APIs.getUserInfo(widget.user),
            builder: (context, snapshot) {
              final data = snapshot.data?.docs;
              final list =
                  data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

              return Row(
                children: [
                  // back button
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      )),

                  // user profile picture
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      width: mq.height * .05,
                      height: mq.height * .05,
                      imageUrl:
                          list.isNotEmpty ? list[0].image : widget.user.image,
                      errorWidget: (context, url, error) => CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                    ),
                  ),

                  // for adding some spaces
                  SizedBox(
                    width: 10,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // for adding some spaces
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),

                      // for adding some spaces
                      SizedBox(
                        height: 2,
                      ),

                      // last user online
                      Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Online'
                                : MyDateUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDateUtil.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: TextStyle(
                            fontSize: 15,
                            // fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 209, 208, 208)),
                      ),
                    ],
                  )
                ],
              );
            }));
  }

  // bottom chat input field
  Widget _chatInput() {
    return Container(
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: mq.height * .01, horizontal: mq.width * .035),
        child: Row(
          children: [
            Expanded(
              child: Card(
                color: Color.fromARGB(
                    255, 36, 36, 36), // Set the card background color to black
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    //emoji button
                    // Comment out the emoji button
                    // IconButton(
                    //   onPressed: () {
                    //     FocusScope.of(context).unfocus();
                    //     setState(() => _showEmoji = !_showEmoji);
                    //   },
                    //   icon: Icon(
                    //     CupertinoIcons.smiley_fill,
                    //     color: Colors.white,
                    //     size: 25,
                    //   ),
                    // ),

                    SizedBox(
                        width: 8), // adding some spaces left of the text input

                    Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji)
                            setState(() => _showEmoji = !_showEmoji);
                        },
                        style: TextStyle(
                            color: Colors.white), // Set text color to white
                        decoration: InputDecoration(
                          hintText: 'Type Messages...', // Set initial hint text
                          hintStyle: TextStyle(
                            color: Color.fromARGB(255, 135, 134, 134),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    //gallery button
                    IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        //picking multiple images
                        final List<XFile>? images = await picker.pickMultiImage(
                          imageQuality: 50,
                        );

                        // uploading and sending image one by one
                        for (var i in images!) {
                          log('Image path: ${i.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(
                        CupertinoIcons.photo,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),

                    //camera button
                    IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 50,
                        );
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(
                        CupertinoIcons.camera_fill,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // send message button
            CupertinoButton(
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  if (_list.isEmpty) {

                    // on first message
                    APIs.sendFirstMessage(
                        widget.user, _textController.text, Type.text);
                  } else {
                    APIs.sendMessage(
                        widget.user, _textController.text, Type.text);
                  }
                  _textController.text = '';
                }
              },
              child: Icon(
                CupertinoIcons.arrow_up_circle_fill,
                color: Colors.white,
                size: 35,
              ),
            )
          ],
        ),
      ),
    );
  }
}
