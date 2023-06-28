

import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/apis.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  @override
  State<StatefulWidget> createState() => _ProfileScreenState();

  const ProfileScreen({super.key, required this.user});
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context). unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile Screen"),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async{
              // for showing prohress dialog
              Dialogs.showProgressBar(context);

              //sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  // for hiding progress diaslog
                  Navigator.pop(context);
                  // for moving to home screen
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                });
              });
            },
            icon: const Icon(Icons.logout),label: Text('Logout'),),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: mq.height * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    width: mq.width ,
                    height: mq.height * .03,
                  ),

                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: CachedNetworkImage(
                          width: mq.height * .2,
                          height: mq.height * .2,
                          fit: BoxFit.fill,
                          imageUrl: widget.user.image,
                          errorWidget: (context, url, error) => CircleAvatar(child: Icon(CupertinoIcons.person),),
                        ),
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: () {},
                          shape: CircleBorder(),
                          color: Colors.white,
                          child: Icon(Icons.edit, color: Colors.blue,),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: mq.height * .03,),
                  Text(widget.user.email, style: TextStyle(color: Colors.black54, fontSize: 16),),
                  SizedBox(height: mq.height * .05,),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) => val != null && val.isNotEmpty ? null : ' Required Feild',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue,),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Name',
                      label: Text('Name')
                    ),
                  ),
                  SizedBox(height: mq.height * .02,),
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) => val != null && val.isNotEmpty ? null : ' Required Feild',
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.info_outline, color: Colors.blue,),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Feeling Happy',
                        label: Text('About')
                    ),
                  ),
                  SizedBox(height: mq.height * .05,),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(shape: StadiumBorder(), minimumSize: Size(mq.width * .4, mq.height * .055)),
                    onPressed: () {
                      if(_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfor().then((value) {
                          Dialogs.showSnackbar(context, 'Profle Update Succesfully');
                        });
                        // log('Update profile success');
                      }
                    },
                    icon: Icon(Icons.edit, size: 28,),
                    label: Text('UPDATE', style: TextStyle(fontSize: 16),),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}