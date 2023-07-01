import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/helper/dialogs.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

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
  String? _image;
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
              
              await APIs.updateActiveStatus(false);

              //sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  // for hiding progress diaslog
                  Navigator.pop(context);
                  // for moving to home screen
                  Navigator.pop(context);

                  APIs.auth = FirebaseAuth.instance;

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
                  //user profile picture
                  Stack(
                    children: [
                      //profile picture
                      _image != null ?
                          //local image
                      ClipRRect(
                          borderRadius:
                          BorderRadius.circular(mq.height * .1),
                          child: Image.file(File(_image!),
                              width: mq.height * .2,
                              height: mq.height * .2,
                              fit: BoxFit.cover))
                      :
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
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: () {
                            _showBottomSheet();
                          },
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

  void _showBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
      return ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
        children: [
          Text(
            'Pick Profile Picture',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: mq.height * .02,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: CircleBorder(),
                  fixedSize: Size(mq.width * .3, mq.height * .15)
                ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // Pick an image.
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if(image != null) {
                      log('Image Path: ${image.path} -- MimeType: ${image.mimeType}');
                      setState(() {
                        _image = image.path;
                      });
                      
                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/add_image.png')
              ),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: CircleBorder(),
                      fixedSize: Size(mq.width * .3, mq.height * .15)
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    // Pick an image.
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if(image != null) {
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });

                      APIs.updateProfilePicture(File(_image!));
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset('images/camera.png')
              )
            ],
          ),
        ],
      );
    });
  }
}