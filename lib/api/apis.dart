import 'dart:developer';

import 'package:chat_app/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //for storing self information
  static late ChatUser me;

  static User get user => auth.currentUser!;

  // for checking if user exit or not
  static Future<bool> userExists() async {
    return (await firestore
        .collection('users')
        .doc(user.uid)
        .get())
        .exists;
  }
  // for getting current user info
  static Future<void> getSelInfo() async {
    return await firestore.collection('users').doc(user.uid).get().then((user) async {
      if(user.exists) {
        me = ChatUser.fromJson(user.data()!);
        log('My Data: ${user.data()}');
      } else {
        await createUser().then((value) => getSelInfo());
      }
    });
  }

  static Future<void> createUser() async {
    final time = DateTime
        .now()
        .microsecondsSinceEpoch
        .toString();
    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey, I'm using Sabo chat",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '');
    return await firestore.collection('users').doc(user.uid).set(
        chatUser.toJson());
  }
  // for getting all users from firebase database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUser() {
    return  firestore.collection('users').where('id', isNotEqualTo: user.uid).snapshots();
  }

  // for updating user information
  static Future<void> updateUserInfor() async {
    await firestore.collection('users').doc(user.uid).update({'name': me.name, 'about': me.about});
  }

}