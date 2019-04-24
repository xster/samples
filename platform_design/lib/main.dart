import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'tab_1.dart';
import 'tab_2.dart';
import 'tab_3.dart';
import 'tab_4.dart';
import 'widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final platformOverride = ValueNotifier<TargetPlatform>(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) {
    // Change this value to better see animations.
    timeDilation = 1;
    // Either Material or Cupertino widgets work in either Material or Cupertino
    // Apps.
    return ValueListenableBuilder(
      valueListenable: platformOverride,
      child: PlatformAdaptingHomePage(platformOverride: platformOverride),
      builder: (BuildContext context, TargetPlatform platform, Widget child) {
        return MaterialApp(
          title: 'Adaptive Music App',
          theme: ThemeData(
            // Use the green theme for Material widgets.
            primarySwatch: Colors.green,
            platform: platform,
          ),
          builder: (BuildContext context, Widget child) {
            return CupertinoTheme(
              // Instead of letting Cupertino widgets auto-adapt to the Material
              // theme (which is green), we're going to use a different theme
              // for Cupertino (which is blue by default).
              data: CupertinoThemeData(),
              child: Material(child: child),
            );
          },
          home: child,
        );
      },
    );
  }
}

// Shows a different type of scaffold depending on the platform.
//
// This file has the most amount of non-sharable code since it behaves the most
// differently between the platforms.
class PlatformAdaptingHomePage extends StatefulWidget {
  PlatformAdaptingHomePage({ Key key, this.platformOverride }) : super(key: key);

  final ValueNotifier<TargetPlatform> platformOverride;

  @override
  _PlatformAdaptingHomePageState createState() => _PlatformAdaptingHomePageState();
}

class _PlatformAdaptingHomePageState extends State<PlatformAdaptingHomePage> {
  // We're keeping global keys because tabs 1 and 2 own a bunch of data.
  // We'd like to keep them as we change platforms and reparent those tabs
  // into different scaffolds.
  final tab1Key = GlobalKey();
  final tab2Key = GlobalKey();

  // In Material, we're using the hamburger menu paradigm. We're flatly listing
  // all possible tabs and injecting this builder into tab 1 which is building
  // the scaffold around the drawer.
  Widget _buildAndroidDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Icon(
                Icons.account_circle,
                color: Colors.green.shade800,
                size: 96,
              ),
            ),
          ),
          ListTile(
            leading: Tab1.androidIcon,
            title: Text(Tab1.title),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Tab2.androidIcon,
            title: Text(Tab2.title),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) => Tab2(key: tab2Key)
              ));
            },
          ),
          ListTile(
            leading: Tab3.androidIcon,
            title: Text(Tab3.title),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) => Tab3()
              ));
            },
          ),
          // Long drawer contents are often segmented.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          ListTile(
            leading: Tab4.androidIcon,
            title: Text(Tab4.title),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) => Tab4()
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidHomePage(BuildContext context, Widget child) {
    return Tab1(
      key: tab1Key,
      androidDrawerBuilder: _buildAndroidDrawer,
      platformOverride: widget.platformOverride,
    );
  }

  // On iOS, the app uses a bottom tab paradigm. Here, all the tabs contents
  // sit inside the tab scaffold which has the tabs.
  //
  // Since more things can be displayed in a drawer than in tabs, we're folding
  // the fourth tab (the settings page) into the the third tab. This is a
  // common pattern on iOS.
  Widget _buildIosHomePage(BuildContext context, Widget child) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            title: Text(Tab1.title),
            icon: Tab1.iosIcon,
          ),
          BottomNavigationBarItem(
            title: Text(Tab2.title),
            icon: Tab2.iosIcon,
          ),
          BottomNavigationBarItem(
            title: Text(Tab3.title),
            icon: Tab3.iosIcon,
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              defaultTitle: Tab1.title,
              builder: (BuildContext context) {
                return Tab1(key: tab1Key, platformOverride: widget.platformOverride);
              },
            );
          case 1:
            return CupertinoTabView(
              defaultTitle: Tab2.title,
              builder: (BuildContext context) {
                return Tab2(key: tab2Key);
              },
            );
          case 2:
            return CupertinoTabView(
              defaultTitle: Tab3.title,
              builder: (BuildContext context) {
                return Tab3();
              },
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformWidget(
      androidBuilder: _buildAndroidHomePage,
      iosBuilder: _buildIosHomePage,
    );
  }
}
