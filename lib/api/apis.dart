import 'package:chat_app/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static User get user => auth.currentUser!;

  // for checking if user exit or not
  static Future<bool> userExists() async {
    return (await firestore
        .collection('users')
        .doc(user.uid)
        .get())
        .exists;
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


}