import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:collection/collection.dart';

void main() {
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
    "Giải thưởng 4"
  ];
  List<Color> colors = [];
  final Stream<int> _selected = Stream<int>.multi((controller) {
    _streamController = controller;
  });
  static StreamSink<int>? _streamController;

  @override
  void initState() {
    super.initState();
    _generateRandomColors();
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
              Image.asset("assets/congrats.png",
                  height: 100), // Thêm ảnh chúc mừng
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
      appBar: AppBar(
        title: Text("Vòng Xoay May Mắn"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettingsDialog,
          ),
        ],
      ),
      body: Column(
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
                  width: 300, // Điều chỉnh theo giao diện mong muốn
                  height: 300,
                  padding: EdgeInsets.all(8), // Viền trắng xung quanh
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 10)
                    ],
                  ),
                  child: FortuneWheel(
                    indicators: [],
                    selected: _selected,
                    items: options.mapIndexed((index, option) {
                      return FortuneItem(
                        child: Text(option,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
              )
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _spinWheel,
            child: Text("QUAY"),
          ),
        ],
      ),
    );
  }
}
