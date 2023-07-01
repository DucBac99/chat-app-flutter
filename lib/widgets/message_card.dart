import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/helper/my_date_util.dart';
import 'package:chat_app/models/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../main.dart';

class MessageCard extends StatefulWidget {

  MessageCard({super.key, required this.message});
  final Message message;

  @override
  State<StatefulWidget> createState() => _MessageCardState();

}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return
      InkWell(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage()
      );
  }
  //sender or another user message
  Widget _blueMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image ? mq.width * .03 : mq.width * .04),
            margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: Colors.blue.shade100,
                border: Border.all(color: Colors.lightBlue),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20)
                )
            ),
            child:
              widget.message.type == Type.text
              ?
              Text(widget.message.msg,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87)
              )
              :
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: widget.message.msg,
                  placeholder: (context, url) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2,),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.image, size: 70,),
                ),
              ),
          ),
        ),
        
        Padding(
          padding:  EdgeInsets.only(right: mq.width * .04),
          child: Text(MyDateUtil.getFormattedTime(context: context, time: widget.message.sent), style: TextStyle(fontSize: 13, color: Colors.black54),),
        ),

      ],
    );
  }
  //our or user message
  Widget _greenMessage() {

    //update last read message if sender and receiver are different
    if(widget.message.read.isNotEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: mq.width * .04,),

            if(widget.message.read.isNotEmpty)
              Icon(Icons.done_all_rounded, color: Colors.blue, size: 20,),

            SizedBox(width: 2),
            //message time
            Text(MyDateUtil.getFormattedTime(context: context, time: widget.message.sent), style: TextStyle(fontSize: 13, color: Colors.black54),),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image ? mq.width * .03 : mq.width * .04),
            margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: Colors.greenAccent.shade100,
                border: Border.all(color: Colors.lightGreen),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20)
                )
            ),
            child: widget.message.type == Type.text
                ?
            Text(widget.message.msg,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87)
            )
                :
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: widget.message.msg,
                placeholder: (context, url) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2,),
                ),
                errorWidget: (context, url, error) => Icon(Icons.image, size: 70,),
              ),
            ),
          ),
        ),

      ],
    );
  }

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
              ?
                _optionItem(
                  icon: Icon(Icons.copy_all_rounded, color: Colors.blue, size: 26,),
                  name: 'Copy Text',
                  onTap: ()  {
                     Clipboard.setData(ClipboardData(text: widget.message.msg)).then((value) {
                      Navigator.pop(context);
                      Dialogs.showSnackbar(context, 'Text Copied!');
                    });
                  }
                )
              :
              _optionItem(
                  icon: Icon(Icons.download_rounded, color: Colors.blue, size: 26,),
                  name: 'Save Image',
                  onTap: ()  {
                    try {
                      log('Image Url: ${widget.message.msg}');
                       GallerySaver.saveImage(widget.message.msg, albumName: 'Sabo Chat').then((success) {
                        Navigator.pop(context);
                        if(success != null && success) {
                          Dialogs.showSnackbar(context, "Save Image Success");
                        }
                      });
                    } catch (e) {
                      log('Error: $e');
                    }
                  }
              ),

              if(isMe)
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              if(widget.message.type == Type.text && isMe)
              _optionItem(
                  icon: Icon(Icons.edit, color: Colors.blue, size: 26,),
                  name: 'Edit Message',
                  onTap: () {
                    Navigator.pop(context);
                    _showMessageUpdateDialog();
                  }
              ),

              if(isMe)
              _optionItem(
                  icon: Icon(Icons.delete_forever, color: Colors.red, size: 26,),
                  name: 'Delete Message',
                  onTap: () async {
                    await APIs.deteteMessage(widget.message).then((value) {
                      Navigator.pop(context);
                    });
                  }
              ),
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              _optionItem(
                  icon: Icon(Icons.remove_red_eye, color: Colors.blue, size: 26,),
                  name: 'Send At: ${MyDateUtil.getLastMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}
              ),

              // _optionItem(
              //     icon: Icon(Icons.remove_red_eye, color: Colors.green, size: 26,),
              //     name: 'Send At:',
              //     onTap: () {}
              // ),
            ],
          );
        });
  }
  void _showMessageUpdateDialog() {
    String updateMsg = widget.message.msg;
    showDialog(context: context, builder: (_) => AlertDialog(
      contentPadding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      title: Row(
        children: [
          Icon(Icons.message, color: Colors.blue, size: 28,),
          Text(' Update Message')
        ],
      ),
      content: TextFormField(
        initialValue: updateMsg,
        maxLines: null,
        onChanged: (value) => updateMsg = value,
        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))
        ),
      ),
      actions: [
        MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: TextStyle(color: Colors.blue, fontSize: 16),),
        ),
        MaterialButton(
          onPressed: () {
            Navigator.pop(context);
            APIs.updateMessage(widget.message, updateMsg);
          },
          child: Text('Update', style: TextStyle(color: Colors.blue, fontSize: 16),),
        )
      ],
    ));
  }
}

class _optionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  _optionItem({required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:  EdgeInsets.only(left: mq.width * .05, top: mq.height * .015, bottom: mq.height *.02),
        child: Row(
          children: [icon, Flexible(child: Text('     $name', style: TextStyle(fontSize: 15, color: Colors.black54, letterSpacing: 0.5),))],
        ),
      ),
    );
  }
}

