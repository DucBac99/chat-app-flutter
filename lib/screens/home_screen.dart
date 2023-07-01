import 'dart:developer';

import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/apis.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _HomeScreenState();

  const HomeScreen({super.key});
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelInfo();


    //for updating user active status according to lifecycle events
    //resume  active or online
    //pause - inactive offline
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
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if(_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }

        },
        child: Scaffold(
          appBar: AppBar(
            leading: Icon(CupertinoIcons.home),
            title: _isSearching ? TextField(
                decoration: InputDecoration(border: InputBorder.none, hintText: 'Name, Email,...'),
                autofocus: true,
                style: TextStyle(fontSize: 17, letterSpacing: 0.5),
                onChanged: (val) {
                  //search logic
                  _searchList.clear();
                  for(var i in _list) {
                    if(i.name.toLowerCase().contains(val.toLowerCase())
                        || i.name.toLowerCase().contains(val.toLowerCase())) {
                      _searchList.add(i);
                    }
                    setState(() {
                      _searchList;
                    });
                  }
                },
            )
                : Text("Sabo Chat"),
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  },
                  icon: Icon(_isSearching ? CupertinoIcons.clear_circled_solid : Icons.search)
              ),
              IconButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: APIs.me,)));
              }, icon: Icon(Icons.more_vert)),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: FloatingActionButton(onPressed: () async{
              await APIs.auth.signOut();
              await GoogleSignIn().signOut();
            }, child: const Icon(Icons.add_comment_rounded),),
          ),
          body: StreamBuilder(
            stream: APIs.getAllUser(),
            builder: (context, snapshot) {
              switch(snapshot.connectionState) {
                  case ConnectionState.waiting:
                    case ConnectionState.none:
                  return Center(child: CircularProgressIndicator(),);

                  case ConnectionState.active:
                  case ConnectionState.done:

                    final data = snapshot.data?.docs;
                    _list = data?.map((e) => ChatUser.fromJson(e.data())). toList() ?? [];
                  if (_list.isNotEmpty) {
                    return ListView.builder(
                        itemCount: _isSearching ? _searchList.length : _list.length,
                        padding: EdgeInsets.only(top: mq.height * .01),
                        physics: BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ChatUserCard(user: _isSearching ? _searchList[index] : _list[index],);
                          // return Text('Name: ${list[index]}');
                        }
                    );
                  } else {
                    return Center(child: Text('No connection Found!', style: TextStyle(fontSize: 20),));
                  }
              }
            },
          ),
        ),
      ),
    );
  }

}