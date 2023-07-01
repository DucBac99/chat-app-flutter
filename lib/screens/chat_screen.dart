import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';
import 'package:chat_app/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  @override
  State<StatefulWidget> createState() => _ChatScreenState();

  ChatScreen({super.key, required this.user});
}

class _ChatScreenState extends State<ChatScreen> {
 List<Message> _list = [];

 //for handling message text changes
 final _textController = TextEditingController();

 bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if(_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }

          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),
            backgroundColor: Color.fromARGB(255, 234, 249, 255),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch(snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return SizedBox();

                        case ConnectionState.active:
                        case ConnectionState.done:

                          final data = snapshot.data?.docs;
                          _list = data?.map((e) => Message.fromJson(e.data())). toList() ?? [];


                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              reverse: true,
                                itemCount: _list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: _list[index],);
                                }
                            );
                          } else {
                            return Center(child: Text('Say hi! 👋', style: TextStyle(fontSize: 20),));
                          }
                      }
                    },
                  ),
                ),


                if(_isUploading)
                  Align(
                    alignment: Alignment.centerRight,
                      child: Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: CircularProgressIndicator(strokeWidth: 2,),
                      )
                  ),

                _chatInput(),

                SizedBox(
                  height: mq.height * .35,
                  child: EmojiPicker(
                  textEditingController: _textController,
                  config: Config(
                    bgColor: Color.fromARGB(255, 234, 249, 255),
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                   ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(user: widget.user)));
      },
      child: StreamBuilder(stream: APIs.getUserInfor(widget.user), builder: (context, snapshot) {

        final data = snapshot.data?.docs;
        final list = data?.map((e) => ChatUser.fromJson(e.data())). toList() ?? [];

        return Row(
          children: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back,
                  color: Colors.black87,)
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(mq.height * .3),
              child: CachedNetworkImage(
                width: mq.height * .05,
                height: mq.height * .05,
                imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person),),
              ),
            ),
            SizedBox(width: 10,),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.isNotEmpty ? list[0].name : widget.user.name,
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2,),
                Text(
                  list.isNotEmpty ?
                    list[0].isOnline ? 'Online' :
                    MyDateUtil.getLastActiveTime(context: context, lastActive: list[0].lastActive)
                  :
                  MyDateUtil.getLastActiveTime(context: context, lastActive: widget.user.lastActive),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,),
                ),
              ],
            ),
          ],
        );
      }),
    );
}

Widget _chatInput() {
    return Padding(
      padding:  EdgeInsets.symmetric(vertical: mq.height * .01, horizontal: mq.width * .025),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  IconButton(onPressed: () {
                    setState(() {
                      FocusScope.of(context).unfocus();
                      _showEmoji = !_showEmoji;
                    });
                  }, icon: Icon(Icons.emoji_emotions, color: Colors.blueAccent,size: 25)),
                  Expanded(child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onTap: () {
                      if(_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: InputDecoration(
                      hintText: 'Type Something....',
                      hintStyle: TextStyle(color: Colors.blueAccent),
                      border: InputBorder.none
                    ),
                  )),
                  IconButton(onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    //picking multiple images
                    final List<XFile> images = await picker.pickMultiImage( imageQuality: 70);
                    for(var i in images) {
                      log('Image path: ${i.path}');
                      setState(() => _isUploading = true);
                      await APIs.sendChatImage(widget.user,File(i.path));
                      setState(() => _isUploading = false);
                    }
                  }, icon: Icon(Icons.image, color: Colors.blueAccent, size: 26)),
                  IconButton(onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

                    if(image != null) {
                      log('Image Path: ${image.path}');
                      setState(() => _isUploading = true);
                      await APIs.sendChatImage(widget.user,File(image.path));
                      setState(() => _isUploading = false);
                    }
                  }, icon: Icon(Icons.camera_alt_rounded, color: Colors.blueAccent, size: 26,)),
                  SizedBox(width: mq.width * .02,)
                ],
              ),
            ),
          ),

          //send message button
          MaterialButton(
            onPressed: () {
              if(_textController.text.isNotEmpty) {
                APIs.sendMessage(widget.user, _textController.text, Type.text);
                _textController.text = '';
              }
            },
            minWidth: 0,
            padding: EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: CircleBorder(),
            color: Colors.green,
            child: Icon(Icons.send,
              color: Colors.white,
              size: 28
              ,)
            ,)
        ],
      ),
    );
}
  
}