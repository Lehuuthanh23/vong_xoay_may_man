import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:collection/collection.dart';
import 'package:udp/udp.dart';
import 'package:vong_xoay_may_man/app/app_sp.dart';

import 'app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyInjection.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vòng Xoay May Mắn',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LuckyWheelScreen(),
    );
  }
}

class LuckyWheelScreen extends StatefulWidget {
  @override
  _LuckyWheelScreenState createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen> {
  List<String> options = [
    "Giải thưởng 1",
    "Giải thưởng 2",
    "Giải thưởng 3",
    "Giải thưởng 4",
    "Giải thưởng 1",
    "Giải thưởng 2",
    "Giải thưởng 3",
    "Giải thưởng 4"
  ];
  List<Color> colors = [];
  final Stream<int> _selected = Stream<int>.multi((controller) {
    _streamController = controller;
  });
  static StreamSink<int>? _streamController;

  List<String> receivedMessages = [];
  UDP? udpReceiver;

  @override
  void initState() {
    super.initState();

    options = AppSP.get('options') ??
        [
          "Giải thưởng 1",
          "Giải thưởng 2",
          "Giải thưởng 3",
          "Giải thưởng 4",
          "Giải thưởng 1",
          "Giải thưởng 2",
          "Giải thưởng 3",
          "Giải thưởng 4"
        ];
    _generateRandomColors();
    _startListening();
  }

  UDP? udpListener;
  // 🟢 1. Bắt đầu lắng nghe tín hiệu UDP từ Sender
  Future<void> _startListening() async {
    try {
      udpListener = await UDP
          .bind(Endpoint.any(port: Port(5001))); // Lắng nghe trên cổng 5001

      udpListener!.asStream().listen((datagram) async {
        if (datagram != null) {
          String message = utf8.decode(datagram.data).trim();
          print("📩 Nhận được tín hiệu từ thiết bị khác: $message");

          // Nếu nhận được "WHERE_ARE_YOU", phản hồi lại "I_AM_HERE"
          if (message == "WHERE_ARE_YOU") {
            await _sendResponse(datagram.address);
          } else {
            setState(() {
              options = message.split(',').map((e) => e.trim()).toList();
              AppSP.set('options', options);
              _generateRandomColors();
            });
          }
        }
      });

      print("👂 Thiết bị đang lắng nghe trên cổng 5001...");
    } catch (e) {
      print("❌ Lỗi khi lắng nghe UDP: $e");
    }
  }

  // 📡 2. Gửi phản hồi lại cho thiết bị gửi
  Future<void> _sendResponse(InternetAddress senderAddress) async {
    try {
      UDP sender = await UDP.bind(Endpoint.any());
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      await sender.send(utf8.encode(androidInfo.name),
          Endpoint.unicast(senderAddress, port: Port(5001)));
      print("✅ Đã phản hồi: ${androidInfo.name}");
      sender.close();
    } catch (e) {
      print("❌ Lỗi khi gửi phản hồi UDP: $e");
    }
  }

  @override
  void dispose() {
    udpListener?.close();
    super.dispose();
  }

  void _generateRandomColors() {
    colors = List.generate(
        options.length,
        (index) =>
            Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image.asset("assets/congrats.png",
              //     height: 100), // Thêm ảnh chúc mừng
              SizedBox(height: 10),
              Text(
                "Chúc mừng!",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                "Bạn đã trúng: $result",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettingsDialog() {
    TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cài đặt vòng quay"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nhập danh sách mục (cách nhau bằng dấu phẩy):"),
            TextField(controller: textController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                options = textController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
                _generateRandomColors();
              });
              Navigator.pop(context);
            },
            child: Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _spinWheel() {
    int resultIndex = Random().nextInt(options.length);
    _streamController?.add(resultIndex);

    Future.delayed(Duration(seconds: 4), () {
      _showResultDialog(options[resultIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/panel.png',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            fit: BoxFit.fill,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Vòng xoay may mắn có viền trắng
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width /
                          2.5, // Điều chỉnh theo giao diện mong muốn
                      height: MediaQuery.of(context).size.width / 2.5,
                      padding: EdgeInsets.all(8), // Viền trắng xung quanh
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.yellow.shade700,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: FortuneWheel(
                        indicators: [],
                        selected: _selected,
                        items: options.mapIndexed((index, option) {
                          return FortuneItem(
                            child: Stack(
                              children: [
                                // Lớp viền
                                Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 01
                                      ..color = const Color.fromARGB(
                                          255, 0, 0, 0), // Màu viền
                                  ),
                                ),
                                // Lớp chữ chính
                                Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255), // Màu chữ
                                  ),
                                ),
                              ],
                            ),
                            style: FortuneItemStyle(
                              color: colors[index],
                              borderColor: Colors.white,
                              borderWidth: 2,
                            ),
                          );
                        }).toList(),
                        onAnimationEnd: () {},
                      ),
                    ),
                  ),
                  // Mũi tên cố định
                  Align(
                    alignment: Alignment.topCenter, // Mũi tên nằm trên cùng
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red, // Màu mũi tên
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: pi, // Xoay ngược mũi tên xuống
                        child: Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 36,
                          color: Colors.white, // Màu icon mũi tên
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _spinWheel,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.black26,
                ),
                child: Text(
                  "QUAY",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Positioned(
          //   top: 0,
          //   right: 5,
          //   child: IconButton(
          //     icon: Icon(
          //       Icons.settings,
          //       color: Colors.white,
          //       size: 30,
          //     ),
          //     onPressed: _openSettingsDialog,
          //   ),
          // ),
        ],
      ),
    );
  }
}
