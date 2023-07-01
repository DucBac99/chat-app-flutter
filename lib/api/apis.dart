import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class APIs {
  // for authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  // for accessing firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  //for storing self information
  static late ChatUser me;

  //to return current user
  static User get user => auth.currentUser!;

  //for accessing firebase messaging (Push Notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  //for sending push notification
  static Future<void> sendPushNotification(ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": chatUser.name,
          "body": msg,
          "android_channel_id": "chats",
        },
        "data": {
          "some_data" : "User ID: ${me.id}",
        },
      };
      var response = await post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
          'key=AAAAs_0y220:APA91bFV9uEP6Q5z40KMGhg6CJBuNz0Hv6S_KUFa7z0P7dN7ap_3nkkvFT4Z_FZoIFEqhnLT6C3PiLciyOQht2VEsx-5DDEjMuDmJ6QBm2CFL3C0VXxEIQ92xubGjIDiIG2jTj_VrhNu'
        },
        body: jsonEncode(body),
      );
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('\nsendPushNotification: $e');
    }
  }

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    fMessaging.getToken().then((t) {
      if(t != null) {
        me.pushToken = t;
        log('Push token: $t');
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

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
        await getFirebaseMessagingToken();
        //for setting user status to active
        APIs.updateActiveStatus(true);
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

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfor(ChatUser chatUser) {
    return  firestore.collection('users').where('id', isEqualTo: chatUser.id).snapshots();
  }

  static Future<void> updateActiveStatus (bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().microsecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    });
  }

  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log('Extenson: $ext');
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref
          .putFile(file, SettableMetadata(contentType: 'image/$ext'))
          .then((p0) {
            log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({'image': me.image});
  }

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';
  // chat screen related apis
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return firestore.collection('chats/${getConversationID(user.id)}/messages/').orderBy('sent', descending: true).snapshots();
  }

  //for send message
  static Future<void> sendMessage (ChatUser chatUser, String msg, Type type) async{
    final time = DateTime.now().microsecondsSinceEpoch.toString();

    //message to send
    final Message message = Message(msg: msg, read: '', toId: chatUser.id, type: type, sent: time, fromId: user.uid);

    final ref = firestore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) => sendPushNotification(chatUser, type == Type.text ?  msg : 'image'));
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    firestore.collection('chats/${getConversationID(message.fromId)}/messages/').doc(message.sent).update(
        {'read': DateTime.now().microsecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    return firestore.collection('chats/${getConversationID(user.id)}/messages/').orderBy('sent', descending: true).limit(1).snapshots();
  }

  static Future<void> sendChatImage (ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${getConversationID(chatUser.id)}/${DateTime.now().microsecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });
    final imageUrl= await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  static Future<void> deteteMessage (Message message) async {
    await firestore.collection('chats/${getConversationID(message.toId)}/messages/').doc(message.sent).delete();
    if(message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  static Future<void> updateMessage (Message message, String updateMsg) async {
    await firestore.collection('chats/${getConversationID(message.toId)}/messages/').doc(message.sent).update(
        {'msg': updateMsg});
    if(message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

}