import 'dart:io';
import 'package:Chat_App/constants/strings.dart';
import 'package:Chat_App/models/message.dart';
import 'package:Chat_App/models/users.dart';
import 'package:Chat_App/provider/ImageUploadProvider.dart';
import 'package:Chat_App/utils/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _goolgeSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _userCollection =
      _firestore.collection(USERS_COLLECTION);

  StorageReference _storageReference;

  Users user = Users();

  Future<User> getCurrentUser() async {
    User currentUser;
    currentUser = await _auth.currentUser;
    return currentUser;
  }

  Future<Users> getUserDetails() async {
    User currentUser = await getCurrentUser();

    DocumentSnapshot documentSnapshot =
        await _userCollection.doc(currentUser.uid).get();

    return Users.fromMap(documentSnapshot.data());
  }

  Future<User> signIn() async {
    GoogleSignInAccount _signInAccout = await _goolgeSignIn.signIn();
    GoogleSignInAuthentication _signInAuthentication =
        await _signInAccout.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: _signInAuthentication.idToken,
      accessToken: _signInAuthentication.accessToken,
    );
    User user = (await _auth.signInWithCredential(credential)).user;
    return user;
  }

  Future<bool> authenticateUser(User user) async {
    QuerySnapshot result = await _firestore
        .collection(USERS_COLLECTION)
        .where(EMAIL_FIELD, isEqualTo: user.email)
        .get();

    final List<DocumentSnapshot> docs = result.docs;

    return docs.length == 0 ? true : false;
  }

  Future<void> addDataToDb(User currentUser) async {
    String username = Utils.getUsername(currentUser.email);
    user = Users(
      uid: currentUser.uid,
      email: currentUser.email,
      name: currentUser.displayName,
      profilePhoto: currentUser.photoURL,
      username: username,
    );

    _firestore
        .collection(USERS_COLLECTION)
        .doc(currentUser.uid)
        .set(user.toMap(user));
  }

  Future<void> signOut() async {
    await _goolgeSignIn.disconnect();
    await _goolgeSignIn.signOut();
    return _auth.signOut();
  }

  Future<List<Users>> fetchAllUsers(User currentUser) async {
    List<Users> userList = List<Users>();

    QuerySnapshot querySnapshot =
        await _firestore.collection(USERS_COLLECTION).get();
    for (var i = 0; i < querySnapshot.docs.length; i++) {
      if (querySnapshot.docs[i].id != currentUser.uid) {
        userList.add(Users.fromMap(querySnapshot.docs[i].data()));
      }
    }
    return userList;
  }

  Future<void> addMessageToDb(
      Message message, Users sender, Users receiver) async {
    var map = message.toMap();

    await _firestore
        .collection(MESSAGES_COLLECTION)
        .doc(message.senderId)
        .collection(message.receiverId)
        .add(map);

    return await _firestore
        .collection(MESSAGES_COLLECTION)
        .doc(message.receiverId)
        .collection(message.senderId)
        .add(map);
  }

  Future<String> uploadImageToStorage(File imageFile) async {
    try {
      _storageReference = FirebaseStorage.instance
          .ref()
          .child('${DateTime.now().millisecondsSinceEpoch}');

      StorageUploadTask _storageUploadTask =
          _storageReference.putFile(imageFile);

      var url =
          await (await _storageUploadTask.onComplete).ref.getDownloadURL();

      print("Hello URL = " + url);

      return url;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void setImageMsg(String url, String receiverId, String senderId) async {
    Message _message;
    _message = Message.imageMessage(
      message: "IMAGE",
      receiverId: receiverId,
      senderId: senderId,
      photoUrl: url,
      timestamp: Timestamp.now(),
      type: 'image',
    );

    var map = _message.toImageMap();

    // Set data to database
    await _firestore
        .collection(MESSAGES_COLLECTION)
        .doc(_message.senderId)
        .collection(_message.receiverId)
        .add(map);

    await _firestore
        .collection(MESSAGES_COLLECTION)
        .doc(_message.receiverId)
        .collection(_message.senderId)
        .add(map);
  }

  void uploadImage(File image, String receiverId, String senderId,
      ImageUploadProvider imageUploadProvider) async {
    imageUploadProvider.setToLoading();

    String url = await uploadImageToStorage(image);

    imageUploadProvider.setToIdle();

    setImageMsg(url, receiverId, senderId);
  }
}
