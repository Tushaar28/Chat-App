import 'package:Chat_App/models/message.dart';
import 'package:Chat_App/models/users.dart';
import 'package:Chat_App/provider/ImageUploadProvider.dart';
import 'package:Chat_App/resources/firebase_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class FirebaseRepository {
  FirebaseMethods _firebaseMethods = FirebaseMethods();

  Future<User> getCurrentUser() => _firebaseMethods.getCurrentUser();

  Future<Users> getUserDetails() => _firebaseMethods.getUserDetails();

  Future<User> signIn() => _firebaseMethods.signIn();

  Future<bool> authenticateUser(User user) =>
      _firebaseMethods.authenticateUser(user);

  Future<void> addDataToDb(User user) => _firebaseMethods.addDataToDb(user);

  Future<void> signOut() => _firebaseMethods.signOut();

  Future<List<Users>> fetchAllUsers(User user) =>
      _firebaseMethods.fetchAllUsers(user);

  Future<void> addMessageToDb(Message message, Users sender, Users receiver) =>
      _firebaseMethods.addMessageToDb(message, sender, receiver);

  void uploadImage({
    @required File image,
    @required String receiverId,
    @required String senderId,
    @required ImageUploadProvider imageUploadProvider,
  }) =>
      _firebaseMethods.uploadImage(
          image, receiverId, senderId, imageUploadProvider);
}
