import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../models/users.dart';
import '../resources/firebase_repository.dart';

class UserProvider with ChangeNotifier {
  Users _user;
  FirebaseRepository _firebaseRepository = FirebaseRepository();

  Users get getUser => _user;

  void refreshUser() async {
    Users user = await _firebaseRepository.getUserDetails();
    _user = user;
    notifyListeners();
  }
}
