import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatMessage {
  bool fromUser;
  String content;

  ChatMessage({required this.fromUser, required this.content});
}

class ChatPage extends StatefulWidget {
  final VoidCallback onChatEnded;

  ChatPage({required this.onChatEnded});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> messages = [];
  final textController = TextEditingController();
  final scrollController = ScrollController();

  stt.SpeechToText speech = stt.SpeechToText();
  FlutterTts flutterTts = FlutterTts();

  bool _isRecording = false;
  String totalRecognizedWords = '';

  int userId = 1; // 사용자 ID 설정
  int? chatId; // 채팅 ID를 저장할 변수

  @override
  void initState() {
    super.initState();
    initializeTts();
    speech.initialize();
  }

  void initializeTts() async {
    await flutterTts.setLanguage("ko-KR");
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      startListening();
    } else {
      stopListening();
    }
  }

  void startListening() {
    speech.listen(
      onResult: (val) {
        totalRecognizedWords += val.recognizedWords + ' ';
      },
      localeId: 'ko_KR',
    );
  }

  void stopListening() {
    speech.stop().then((value) {
      _handleSubmitted(totalRecognizedWords);
      totalRecognizedWords = '';
    });
  }

  // 채팅 메시지 생성
  void _createChatMessage(String content, {required bool fromUser}) {
    setState(() {
      _isRecording = false;
      messages.add(ChatMessage(fromUser: fromUser, content: content));

      if (!fromUser) {
        flutterTts.speak(content);
      }

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // 텍스트 입력 메시지 처리 및 AI 답변 요청
  void _handleSubmitted(String text) {
    textController.clear();
    _createChatMessage(text, fromUser: true);

    fetchAIResponse(text).then((aiResponse) {
      _createChatMessage(aiResponse, fromUser: false);
    }).catchError((error) {
      _createChatMessage('안타깝게도, 답변을 가져오는 데 실패했습니다.', fromUser: false);
    });
  }

  Future<String> fetchAIResponse(String userInput) async {
    var url =
        'https://port-0-caring-server-am952nlssay0u1.sel5.cloudtype.app/chat/';
    if (chatId == null) {
      // 채팅이 시작되지 않았다면 채팅을 시작
      var startUrl =
          'https://port-0-caring-server-am952nlssay0u1.sel5.cloudtype.app/chat/start';
      var startResponse = await http.post(
        Uri.parse(startUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'userId': userId,
        }),
      );

      if (startResponse.statusCode == 200) {
        chatId = jsonDecode(startResponse.body)['chatId'];
        return jsonDecode(startResponse.body)['message'];
      } else {
        throw Exception('Failed to start chat.');
      }
    }

    if (chatId != null) {
      // chatId 가 null이 아닌지 확인
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'chatId': chatId,
          'message': userInput,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['message']
            ['message']; // API 응답 형태에 따라 수정해야 합니다.
      } else {
        throw Exception('Failed to fetch response from API.');
      }
    }
    return 'Invalid chatId'; // chatId 가 null인 경우 반환할 메시지
  }

// 채팅 종료 처리
  void endChat() async {
    if (chatId != null) {
      var endUrl =
          'https://port-0-caring-server-am952nlssay0u1.sel5.cloudtype.app/chat/end';
      await http.post(
        Uri.parse(endUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'chatId': chatId!,
        }),
      );
      chatId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6083FF),
        title: Text('채팅 페이지'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.mic),
            onPressed: _toggleRecording,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '녹음 중...',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return messages[index].fromUser
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.all(10.0),
                            padding: EdgeInsets.all(10.0),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF6083FF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                bottomLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                                bottomRight: Radius.circular(0.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              messages[index].content,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.all(10.0),
                            padding: EdgeInsets.all(10.0),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(0.0),
                                bottomLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                                bottomRight: Radius.circular(10.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(messages[index].content),
                          ),
                        ],
                      );
              },
            ),
          ),
          TextField(
            controller: textController,
            onSubmitted: (text) {
              _handleSubmitted(text); // 이 부분이 수정되었습니다.
            },
          ),
          ElevatedButton(
            onPressed: () {
              widget.onChatEnded();
              Navigator.pop(context);
            },
            child: Text('대화 끝내기'),
            style: ElevatedButton.styleFrom(
              primary: Color(0xFFFF6060),
              onPrimary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
