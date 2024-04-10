import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/helper/dialogs.dart';
import 'package:xpress/main.dart';
import 'package:xpress/models/chat_user.dart';
import 'package:xpress/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding the keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          //app bar
          appBar: AppBar(
            title: const Text('My Profile'),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 15),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.white,
              onPressed: () async {
                //for showing progress dialog
                Dialogs.showProgressBar(context);

                await APIs.updateActiveStatus(false);

                // sign out from app
                await APIs.auth.signOut().then((value) async {
                  await GoogleSignIn().signOut().then((value) {
                    // for hiding the progress bar
                    Navigator.pop(context);

                    APIs.auth = FirebaseAuth.instance;

                    // for moving to home screen
                    Navigator.pop(context);
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => loginScreen()));
                  });
                });
              },
              icon: Icon(
                Icons.logout_outlined,
              ),
              label: Text('Logout'),
            ),
          ),
          body: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // for adding some space
                    SizedBox(width: mq.width, height: mq.height * .03),

                    // user profile picture
                    Stack(
                      children: [
                        // profile picture
                        _image != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(_image!),
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover,
                                ),
                              )
                            :
                            // image from server / default
                            ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  width: mq.height * .2,
                                  height: mq.height * .2,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.user.image,
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    child: Icon(CupertinoIcons.person),
                                  ),
                                ),
                              ),

                        // edit image button
                        Positioned(
                          bottom: 0,
                          // right: 40,
                          left: 100,
                          child: MaterialButton(
                            onPressed: () {
                              _showBottomSheet();
                            },
                            child: Icon(Icons.edit),
                            color: Colors.white,
                            shape: CircleBorder(),
                          ),
                        )
                      ],
                    ),

                    // for adding some space
                    SizedBox(height: mq.height * .03),

                    // user email label
                    Text(
                      widget.user.email,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),

                    //for adding some space
                    SizedBox(height: mq.height * .02),

                    // for editing name input field
                    TextFormField(
                      initialValue: widget.user.name,
                      onSaved: (val) => APIs.me.name = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                          hintStyle: TextStyle(color: Colors.black),
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.white)),
                    ),

                    //for adding some space
                    SizedBox(height: mq.height * .02),

                    // for editing about section
                    TextFormField(
                      initialValue: widget.user.about,
                      onSaved: (val) => APIs.me.about = val ?? '',
                      validator: (val) => val != null && val.isNotEmpty
                          ? null
                          : 'Required Field',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15)),
                          hintStyle: TextStyle(color: Colors.black),
                          labelText: 'About',
                          labelStyle: TextStyle(color: Colors.white)),
                    ),

                    //for adding some space
                    SizedBox(height: mq.height * .05),

                    // update profile button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(mq.width * .5, mq.height * .06),
                          backgroundColor: Colors.white),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          APIs.updateUserInfo().then((value) {
                            Dialogs.showSnackbar(
                                context, 'Updated Sucessfully');
                          });
                        }
                      },
                      icon: Icon(Icons.edit),
                      label: Text(
                        'Update',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
    );
  }

// bottom sheet for choosing profile picture
  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding:
                EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
            children: [
              Text(
                // pick profile picture level
                'Change Profile Picture Through,',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(
                height: mq.height * .02,
              ),

              // buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // take picture from gallery button
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          log('Image Path: ${image.path} -- MimeType: ${image.mimeType}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          // for hiding the bottomsheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/add_image.png')),

                  ElevatedButton(
                      // take picture from camera button
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: CircleBorder(),
                          fixedSize: Size(mq.width * .3, mq.height * .15)),
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() {
                            _image = image.path;
                          });
                          APIs.updateProfilePicture(File(_image!));
                          // for hiding the bottomsheet
                          Navigator.pop(context);
                        }
                      },
                      child: Image.asset('images/camera.png'))
                ],
              )
            ],
          );
        });
  }



}
