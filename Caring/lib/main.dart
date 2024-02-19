import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Chat.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    checkMicrophonePermissions(); // 이 부분이 추가되었습니다.
    return MaterialApp(
      title: 'Caring',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryIconTheme:
            IconThemeData(color: Colors.white), // 아이콘 색상을 검은색으로 설정
      ),
      home: HomePage(),
    );
  }
}

void checkMicrophonePermissions() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    if (await Permission.microphone.request().isGranted) {
      // 사용자가 권한을 수락했습니다. 마이크를 사용하세요.
    } else {
      // 사용자가 권한을 거부했습니다. 적절한 처리를 해야 합니다.
    }
  } else {
    // 이미 권한이 부여되었습니다. 마이크를 사용하세요.
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String message = '오늘 아직 대화를 하지 않았어요.\n아래 버튼을 눌러\n대화를 시작하세요!';

  void updateMessage() {
    setState(() {
      message = '오늘 대화를 마무리 했어요.\n더 이야기 하고싶다면\n아래 버튼을 눌러 대화를 시작하세요!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFF6083FF),
        title: Text('Caring'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('메뉴'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('아직 메뉴가 없습니다.'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ChatPage(onChatEnded: updateMessage)),
                        );
                      },
                      child: Icon(Icons.phone),
                    ),
                    SizedBox(height: 20.0),
                    Text(
                      '대화 시작하기',
                      style: TextStyle(color: Color(0xFF6083FF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
