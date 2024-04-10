import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:xpress/main.dart';
import 'package:xpress/models/chat_user.dart';
import 'package:xpress/screens/view_profile_screens.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white30,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,
        child: Stack(
          children: [
            // user profile picture
            Positioned(
              top: mq.height * .06,
              left: mq.width * .08,
              child: Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    width: mq.width * .45,
                    fit: BoxFit.cover,
                    imageUrl: user.image,
                    errorWidget: (context, url, error) => CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),
              ),
            ),

            // user name
            Positioned(
              left: mq.width * .04,
              top: mq.height * .02,
              width: mq.width * .55,
              child: Text(
                user.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // info button
            Positioned(
              top: mq.height * .01,
              right: mq.width * .02,
              child: Align(
                  alignment: Alignment.topRight,
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ViewProfileScreen(user: user)));
                    },
                    minWidth: 0,
                    padding: EdgeInsets.all(0),
                    shape: CircleBorder(),
                    child: Icon(
                      CupertinoIcons.info_circle_fill,
                      color: Colors.white,
                      size: 30,
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
