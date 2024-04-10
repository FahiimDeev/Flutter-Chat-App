import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xpress/Widgets/chat_user_card.dart';
import 'package:xpress/api/apis.dart';
import 'package:xpress/helper/dialogs.dart';
import 'package:xpress/main.dart';
import 'package:xpress/models/chat_user.dart';
import 'package:xpress/screens/profile_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // for storing all user
  List<ChatUser> _list = [];

  // for storing search items
  final List<ChatUser> _searchList = [];

  //for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');

      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Focus.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          //app bar
          appBar: AppBar(
            leading: Icon(CupertinoIcons.home),
            title: _isSearching
                ? TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Name, Email,....',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    onChanged: (val) {
                      // search logic
                      _searchList.clear();
                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                      }
                      setState(() {});
                    },
                  )
                : Text('Xpress'),
            actions: [
              //search user
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search,
                ),
              ),
              //three dots / more feature button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        user: APIs.me,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.more_vert),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 40, right: 30),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog();
              },
              backgroundColor: Colors.white,
              child: Icon(
                Icons.add_circle_outlined,
                color: Colors.black,
              ),
            ),
          ),

          //body
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),

            //get id of only known users
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

                //if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),

                    //get only those user, who's ids are provided
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        //if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return const Center(
                        //     child: CircularProgressIndicator());

                        //if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list = data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            log('if called here');
                            return ListView.builder(
                                itemCount: _isSearching
                                    ? _searchList.length
                                    : _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChatUserCard(
                                      user: _isSearching
                                          ? _searchList[index]
                                          : _list[index]);
                                });
                          } else {
                            return Center(
                              child: Text('No Connections Found!',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white)),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  // for adding new user
  void _addChatUserDialog() {
    String email = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding:
            const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

        //title
        title: Row(
          children: const [
            Icon(
              Icons.person_add_alt_1,
              color: Colors.black,
              size: 28,
            ),
            Text('  Add User')
          ],
        ),

        //content
        content: TextFormField(
          maxLines: null,
          onChanged: (value) => email = value,
          decoration: InputDecoration(
            hintText: 'Enter Email',
            hintStyle: TextStyle(color: Colors.black45),
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),

        //actions
        actions: [
          //cancel button
          MaterialButton(
            onPressed: () {
              //hide alert dialog
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),

          //update button
          MaterialButton(
            onPressed: () async {
              //hide alert dialog
              Navigator.pop(context);
              if (email.isNotEmpty) {
                await APIs.addChatUser(email).then((value) {
                  if (!value) {
                    Dialogs.showSnackbar(context, 'User does not Exists!');
                  }
                });
              }
            },
            child: Text(
              'Add',
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
