import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/apis.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _HomeScreenState();

  const HomeScreen({super.key});
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> list = [];
  @override
  void initState() {
    super.initState();
    APIs.getSelInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(CupertinoIcons.home),
        title: const Text("Sabo Chat"),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
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
                list = data?.map((e) => ChatUser.fromJson(e.data())). toList() ?? [];
              if (list.isNotEmpty) {
                return ListView.builder(
                    itemCount: list.length,
                    padding: EdgeInsets.only(top: mq.height * .01),
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return ChatUserCard(user: list[index],);
                      // return Text('Name: ${list[index]}');
                    }
                );
              } else {
                return Center(child: Text('No connection Found!', style: TextStyle(fontSize: 20),));
              }
          }
        },
      ),
    );
  }

}