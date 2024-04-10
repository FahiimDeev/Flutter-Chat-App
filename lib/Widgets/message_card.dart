import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/helper/dialogs.dart';
import 'package:xpress/helper/my_date_util.dart';
import 'package:xpress/main.dart';
import 'package:xpress/models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({Key? key, required this.message}) : super(key: key);

  final Message message;

  @override
  _MessageCardState createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;

    return InkWell(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

// sender or another user message
  Widget _blueMessage() {
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 270,
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: widget.message.sent,
            ),
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

// our or user message
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: mq.width * .04),
            if (widget.message.read.isNotEmpty)
              Icon(
                Icons.done_all_rounded,
                color: Colors.white,
                size: 20,
              ),
            SizedBox(width: 2),
            Text(
              MyDateUtil.getFormattedTime(
                context: context,
                time: widget.message.sent,
              ),
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      memCacheWidth: 200,
                      memCacheHeight: 270,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

// bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ? // copy item
                  _OptionItem(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          // for hiding the bottom sheet
                          Navigator.pop(context);
                          Dialogs.showSnackbar(context, 'Message Copied');
                        });
                      })
                  : // save item
                  _OptionItem(
                      icon: Icon(
                        Icons.save_alt_outlined,
                        color: Colors.black,
                        size: 28,
                      ),
                      name: 'Save Image',
                      onTap: () async {
                        try {
                          // Show progress indicator
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              );
                            },
                          );

                          // Save the image
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'Xpress')
                              .then((success) {
                            // Hide the progress indicator
                            Navigator.pop(context);

                            // Hide the bottom sheet
                            Navigator.pop(context);

                            // Show snackbar if image is saved successfully
                            if (success != null && success) {
                              Dialogs.showSnackbar(
                                  context, 'Image saved successfully');
                            }
                          });
                        } catch (e) {
                          log('ErrorWhileSavingImg: $e');
                        }
                      }),

              if (isMe)
                Divider(
                  // color: Colors.black,
                  indent: mq.width * .02,
                  endIndent: mq.width * .04,
                ),
              if (widget.message.type == Type.text && isMe)
                // edit item
                _OptionItem(
                    icon: Icon(
                      Icons.edit_document,
                      color: Colors.black,
                      size: 28,
                    ),
                    name: 'Edit Message',
                    onTap: () {
                      //for hiding the bottom sheet
                      Navigator.pop(context);
                      _showMessageUpdateDialog();
                    }),

              // delete item / message
              if (isMe)
                _OptionItem(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    name: 'Delete Message',
                    onTap: () async {
                      await APIs.deleteMessage(widget.message).then((value) {
                        // for hiding the bottom sheet
                        Navigator.pop(context);
                      });
                    }),

              Divider(
                // color: Colors.black,
                indent: mq.width * .02,
                endIndent: mq.width * .04,
              ),

              // sent item
              _OptionItem(
                  icon: Icon(
                    Icons.watch_later,
                    color: Colors.black,
                    size: 28,
                  ),
                  name:
                      'Sent Time: ${MyDateUtil.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              // read item
              _OptionItem(
                  icon: Icon(
                    Icons.watch_later_outlined,
                    color: Colors.green,
                    size: 28,
                  ),
                  name: widget.message.read.isEmpty
                      ? 'Read Time: Not seen yet'
                      : 'Read Time: ${MyDateUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  // dialog for updating message content
  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),

              //title
              title: Row(
                children: const [
                  Icon(
                    Icons.update,
                    color: Colors.black,
                    size: 28,
                  ),
                  Text(' Update Message')
                ],
              ),

              //content
              content: TextFormField(
                initialValue: updatedMsg,
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    )),

                //update button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                      APIs.updateMessage(widget.message, updatedMsg);
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ))
              ],
            ));
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
          left: mq.width * .05,
          bottom: mq.height * .025,
          top: mq.height * .015,
        ),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text(
              '   ${name}',
              style: TextStyle(fontSize: 18),
            ))
          ],
        ),
      ),
    );
  }
}
