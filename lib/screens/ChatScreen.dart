import 'dart:convert';

import 'package:Chat_App/models/message.dart';
import 'package:Chat_App/resources/firebase_repository.dart';
import 'package:Chat_App/widgets/custom_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/users.dart';
import '../utils/universal_variables.dart';
import '../widgets/appbar.dart';

class ChatScreen extends StatefulWidget {
  final Users receiver;

  ChatScreen({this.receiver});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseRepository _repository = FirebaseRepository();
  TextEditingController textFieldController = TextEditingController();
  bool isWriting = false;
  Users sender;
  String _currentUserId;

  @override
  void initState() {
    super.initState();
    _repository.getCurrentUser().then((User user) {
      _currentUserId = user.uid;
      setState(() {
        sender = Users(
          uid: user.uid,
          name: user.displayName,
          profilePhoto: user.photoURL,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      appBar: customAppBar(context),
      body: Column(
        children: <Widget>[
          Flexible(
            child: messageList(),
          ),
          chatControls(),
        ],
      ),
    );
  }

  Widget messageList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("messages")
          .doc(_currentUserId)
          .collection(widget.receiver.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            return chatMessageItem(snapshot.data.docs[index]);
          },
        );
      },
    );
  }

  Widget chatMessageItem(DocumentSnapshot snapshot) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Container(
        alignment: snapshot.data()['senderId'] == _currentUserId
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: snapshot.data()['senderId'] == _currentUserId
            ? senderLayout(snapshot)
            : receiverLayout(snapshot),
      ),
    );
  }

  Widget senderLayout(DocumentSnapshot snapshot) {
    Radius messageRadius = Radius.circular(10);

    return Container(
      margin: EdgeInsets.only(
        top: 12,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(
        color: UniversalVariables.senderColor,
        borderRadius: BorderRadius.only(
          topLeft: messageRadius,
          topRight: messageRadius,
          bottomLeft: messageRadius,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: getMessage(snapshot),
      ),
    );
  }

  getMessage(DocumentSnapshot snapshot) {
    return Text(
      snapshot.data()['message'],
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    );
  }

  Widget receiverLayout(DocumentSnapshot snapshot) {
    Radius messageRadius = Radius.circular(10);

    return Container(
      margin: EdgeInsets.only(
        top: 12,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(
        color: UniversalVariables.receiverColor,
        borderRadius: BorderRadius.only(
          bottomRight: messageRadius,
          topRight: messageRadius,
          bottomLeft: messageRadius,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: getMessage(snapshot),
      ),
    );
  }

  Widget chatControls() {
    setWritingTo(bool val) {
      setState(() {
        isWriting = val;
      });
    }

    addMediaModal(context) {
      showModalBottomSheet(
        context: context,
        elevation: 0,
        backgroundColor: UniversalVariables.blackColor,
        builder: (conetxt) {
          return Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 15,
                ),
                child: Row(
                  children: <Widget>[
                    FlatButton(
                      child: Icon(
                        Icons.close,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Content and Tools",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  children: <Widget>[
                    ModalTile(
                      title: "Media",
                      subtitle: "Share photos and videos",
                      icon: Icons.image,
                    ),
                    ModalTile(
                      title: "File",
                      subtitle: "Share files",
                      icon: Icons.tab,
                    ),
                    ModalTile(
                      title: "Contact",
                      subtitle: "Share contacts",
                      icon: Icons.contacts,
                    ),
                    ModalTile(
                      title: "Location",
                      subtitle: "Share location",
                      icon: Icons.add_location,
                    ),
                    ModalTile(
                      title: "Schedule Call",
                      subtitle: "Arrange Skype call and get reminders",
                      icon: Icons.schedule,
                    ),
                    ModalTile(
                      title: "Create Poll",
                      subtitle: "Share Polls",
                      icon: Icons.poll,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => addMediaModal(context),
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: UniversalVariables.fabGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
              ),
            ),
          ),
          SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextField(
              controller: textFieldController,
              style: TextStyle(
                color: Colors.white,
              ),
              onChanged: (val) {
                (val.length > 0 && val.trim() != "")
                    ? setWritingTo(true)
                    : setWritingTo(false);
              },
              decoration: InputDecoration(
                hintText: "Type message",
                hintStyle: TextStyle(
                  color: UniversalVariables.greyColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                    const Radius.circular(50),
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                filled: true,
                fillColor: UniversalVariables.separatorColor,
                suffixIcon: GestureDetector(
                  onTap: () {},
                  child: Icon(
                    Icons.face,
                  ),
                ),
              ),
            ),
          ),
          isWriting
              ? Container()
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  child: Icon(
                    Icons.record_voice_over,
                  ),
                ),
          isWriting
              ? Container()
              : Icon(
                  Icons.camera_alt,
                ),
          isWriting
              ? Container(
                  margin: EdgeInsets.only(
                    left: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: UniversalVariables.fabGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      size: 15,
                    ),
                    onPressed: () => sendMessage(),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  sendMessage() {
    var text = textFieldController.text;
    Message _message = Message(
      receiverId: widget.receiver.uid,
      senderId: sender.uid,
      message: text,
      timestamp: FieldValue.serverTimestamp(),
      type: 'text',
    );

    setState(() {
      isWriting = false;
    });

    _repository.addMessageToDb(_message, sender, widget.receiver);
  }

  CustomAppBar customAppBar(BuildContext context) {
    return CustomAppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      title: Text(
        widget.receiver.name,
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.video_call,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(
            Icons.phone,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class ModalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const ModalTile({
    @required this.icon,
    @required this.subtitle,
    @required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: CustomTile(
        mini: false,
        leading: Container(
          margin: EdgeInsets.only(
            right: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: UniversalVariables.receiverColor,
          ),
          padding: EdgeInsets.all(10),
          child: Icon(
            icon,
            color: UniversalVariables.greyColor,
            size: 38,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: UniversalVariables.greyColor,
            fontSize: 14,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
