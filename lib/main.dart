import 'package:Chat_App/provider/user_provider.dart';
import 'package:Chat_App/resources/firebase_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/HomeScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/SearchScreen.dart';
import './provider/ImageUploadProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseRepository _repository = FirebaseRepository();
  @override
  Widget build(BuildContext context) {
    //_repository.signOut(); // For signing out

    // FirebaseFirestore.instance
    //     .collection("users")
    //     .doc()
    //     .set({"name": "Tushaar"});

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImageUploadProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: "Chat App",
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/search_screen': (context) => SearchScreen(),
        },
        theme: ThemeData(
          brightness: Brightness.dark,
        ),
        home: FutureBuilder(
          future: _repository.getCurrentUser(),
          builder: (context, AsyncSnapshot<User> snapshot) {
            if (snapshot.hasData)
              return HomeScreen();
            else
              return LoginScreen();
          },
        ),
      ),
    );
  }
}
