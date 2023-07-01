import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../api/apis.dart';
import '../main.dart';

class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;
  @override
  State<StatefulWidget> createState() => _ViewProfileScreenState();

  const ViewProfileScreen({super.key, required this.user});
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context). unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title:  Text(widget.user.name),
        ),
        floatingActionButton:  Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Joined On: ', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),),
            Text(MyDateUtil.getLastMessageTime(context: context, time: widget.user.createdAt, showYear: true), style: TextStyle(color: Colors.black87, fontSize: 16),),
          ],
        ),
        body: Padding(
          padding:  EdgeInsets.symmetric(horizontal: mq.height * .05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: mq.width ,
                  height: mq.height * .03,
                ),
                //user profile picture
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .1),
                      child: CachedNetworkImage(
                        width: mq.height * .2,
                        height: mq.height * .2,
                        fit: BoxFit.cover,
                        imageUrl: widget.user.image,
                        errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person),),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mq.height * .03,),
                Text(widget.user.email, style: TextStyle(color: Colors.black87, fontSize: 16),),
                SizedBox(height: mq.height * .02,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('About: ', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),),
                    Text(widget.user.about, style: TextStyle(color: Colors.black87, fontSize: 16),),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}