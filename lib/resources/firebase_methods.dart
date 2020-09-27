import 'package:Chat_App/models/message.dart';
import 'package:Chat_App/models/users.dart';
import 'package:Chat_App/utils/utilities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn _goolgeSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Users user = Users();

  Future<User> getCurrentUser() async {
    User currentUser;
    currentUser = await _auth.currentUser;
    return currentUser;
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
        .collection("users")
        .where("email", isEqualTo: user.email)
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

    _firestore.collection("users").doc(currentUser.uid).set(user.toMap(user));
  }

  Future<void> signOut() async {
    await _goolgeSignIn.disconnect();
    await _goolgeSignIn.signOut();
    return _auth.signOut();
  }

  Future<List<Users>> fetchAllUsers(User currentUser) async {
    List<Users> userList = List<Users>();

    QuerySnapshot querySnapshot = await _firestore.collection("users").get();
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
        .collection("messages")
        .doc(message.senderId)
        .collection(message.receiverId)
        .add(map);

    return await _firestore
        .collection("messages")
        .doc(message.receiverId)
        .collection(message.senderId)
        .add(map);
  }
}
