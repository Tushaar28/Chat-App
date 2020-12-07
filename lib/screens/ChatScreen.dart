import 'dart:io';

import 'package:Chat_App/constants/strings.dart';
import 'package:Chat_App/models/message.dart';
import 'package:Chat_App/resources/firebase_repository.dart';
import 'package:Chat_App/screens/widgets/Cached_Image.dart';
import 'package:Chat_App/utils/call_utilities.dart';
import 'package:Chat_App/utils/permissions.dart';
import 'package:Chat_App/utils/utilities.dart';
import 'package:Chat_App/widgets/custom_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker/emoji_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/users.dart';
import '../utils/universal_variables.dart';
import '../widgets/appbar.dart';
import '../provider/ImageUploadProvider.dart';
import '../enum/ViewState.dart';

class ChatScreen extends StatefulWidget {
  final Users receiver;

  ChatScreen({this.receiver});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FirebaseRepository _repository = FirebaseRepository();

  TextEditingController textFieldController = TextEditingController();
  ScrollController _listScrollController = ScrollController();
  FocusNode textFieldFocus = FocusNode();

  ImageUploadProvider _imageUploadProvider;

  bool isWriting = false;
  bool showEmojiPicker = false;

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

  showKeyboard() => textFieldFocus.requestFocus();

  hideKeyboard() => textFieldFocus.unfocus();

  hideEmojiContainer() {
    setState(() {
      showEmojiPicker = false;
    });
  }

  showEmojiContainer() {
    setState(() {
      showEmojiPicker = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _imageUploadProvider = Provider.of<ImageUploadProvider>(context);

    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      appBar: customAppBar(context),
      body: Column(
        children: <Widget>[
          Flexible(
            child: messageList(),
          ),
          _imageUploadProvider.getViewState == ViewState.LOADING
              ? Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(
                    right: 15,
                  ),
                  child: CircularProgressIndicator(),
                )
              : Container(),
          chatControls(),
          showEmojiPicker
              ? Container(
                  child: emojiContainer(),
                )
              : Container()
        ],
      ),
    );
  }

  emojiContainer() {
    return EmojiPicker(
      bgColor: UniversalVariables.separatorColor,
      indicatorColor: UniversalVariables.blueColor,
      rows: 3,
      columns: 7,
      onEmojiSelected: (emoji, category) {
        setState(() {
          isWriting = true;
        });
        textFieldController.text = textFieldController.text + emoji.emoji;
      },
    );
  }

  Widget messageList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection(MESSAGES_COLLECTION)
          .doc(_currentUserId)
          .collection(widget.receiver.uid)
          .orderBy(TIMESTAMP_FIELD, descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        // Moves the screen to end of screen when new message arrives
        // SchedulerBinding.instance.addPostFrameCallback((_) {
        //   _listScrollController.animateTo(
        //     _listScrollController
        //         .position.minScrollExtent, // Move to End of List
        //     duration: Duration(milliseconds: 250),
        //     curve: Curves.easeInOut,
        //   );
        // });

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: snapshot.data.docs.length,
          reverse: true,
          controller: _listScrollController,
          itemBuilder: (context, index) {
            return chatMessageItem(snapshot.data.docs[index]);
          },
        );
      },
    );
  }

  Widget chatMessageItem(DocumentSnapshot snapshot) {
    Message _message = Message.fromMap(snapshot.data());
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Container(
        alignment: _message.senderId == _currentUserId
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: _message.senderId == _currentUserId
            ? senderLayout(_message)
            : receiverLayout(_message),
      ),
    );
  }

  Widget senderLayout(Message _message) {
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
        child: getMessage(_message),
      ),
    );
  }

  getMessage(Message _message) {
    return _message.type != MESSAGE_TYPE_IMAGE
        ? Text(
            _message.message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          )
        : _message.photoUrl != null
            ? CachedImage(
                _message.photoUrl,
                height: 250,
                width: 250,
                radius: 10,
              )
            : Text("URL was null");
  }

  pickImage({@required ImageSource source}) async {
    File selectedImage = await Utils.pickImage(source: source);
    _repository.uploadImage(
      image: selectedImage,
      receiverId: widget.receiver.uid,
      senderId: _currentUserId,
      imageUploadProvider: _imageUploadProvider,
    );
  }

  Widget receiverLayout(Message _message) {
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
        child: getMessage(_message),
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
                      onTap: () => pickImage(source: ImageSource.gallery),
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
            child: Stack(
              children: [
                TextField(
                  controller: textFieldController,
                  focusNode: textFieldFocus,
                  onTap: () => hideEmojiContainer(),
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
                  ),
                ),
                IconButton(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    if (!showEmojiPicker) {
                      // Keyboard is visible
                      hideKeyboard();
                      showEmojiContainer();
                    } else {
                      // Keyboard is hidden
                      showKeyboard();
                      hideEmojiContainer();
                    }
                  },
                  icon: Icon(
                    Icons.face,
                  ),
                ),
              ],
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
              : GestureDetector(
                  onTap: () => pickImage(source: ImageSource.camera),
                  child: Icon(
                    Icons.camera_alt,
                  ),
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
      timestamp: Timestamp.now(),
      type: 'text',
    );

    setState(() {
      isWriting = false;
    });
    textFieldController.text = "";
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
          onPressed: () async =>
              await Permissions.cameraAndMicrophonePermissionsGranted()
                  ? CallUtils.dial(
                      from: sender,
                      to: widget.receiver,
                      context: context,
                    )
                  : {},
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
  final Function onTap;

  const ModalTile({
    @required this.icon,
    @required this.subtitle,
    @required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: CustomTile(
        mini: false,
        onTap: onTap,
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
