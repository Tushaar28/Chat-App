import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/universal_variables.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    double _labelFontSize = 10;

    return Scaffold(
      backgroundColor: UniversalVariables.blackColor,
      body: PageView(
        children: <Widget>[
          Center(
            child: Text(
              "Chats",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Text(
              "Calls",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          Center(
            child: Text(
              "Search",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        //  physics: NeverScrollableScrollPhysics(),          // For disabling horizontal swipe
      ),
      bottomNavigationBar: Container(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: CupertinoTabBar(
            backgroundColor: UniversalVariables.blackColor,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.chat,
                  color: (_page == 0)
                      ? UniversalVariables.lightBlueColor
                      : UniversalVariables.greyColor,
                ),
                title: Text(
                  "Chats",
                  style: TextStyle(
                    fontSize: _labelFontSize,
                    color: (_page == 0)
                        ? UniversalVariables.lightBlueColor
                        : Colors.grey,
                  ),
                ),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.call,
                  color: (_page == 1)
                      ? UniversalVariables.lightBlueColor
                      : UniversalVariables.greyColor,
                ),
                title: Text(
                  "Calls",
                  style: TextStyle(
                    fontSize: _labelFontSize,
                    color: (_page == 1)
                        ? UniversalVariables.lightBlueColor
                        : Colors.grey,
                  ),
                ),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.search,
                  color: (_page == 2)
                      ? UniversalVariables.lightBlueColor
                      : UniversalVariables.greyColor,
                ),
                title: Text(
                  "Chats",
                  style: TextStyle(
                    fontSize: _labelFontSize,
                    color: (_page == 2)
                        ? UniversalVariables.lightBlueColor
                        : Colors.grey,
                  ),
                ),
              ),
            ],
            onTap: navigationTapped,
            currentIndex: _page,
          ),
        ),
      ),
    );
  }
}
