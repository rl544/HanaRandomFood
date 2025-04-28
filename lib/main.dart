import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:window_size/window_size.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  setWindowTitle('하나랜덤식당');
  DesktopWindow.setWindowSize(Size(480,740));
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterNativeSplash.remove();
  runApp(RandomSelectorApp());
}


class RandomSelectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '명동 식당고르기',
      home: RandomSelectorScreen(),
    );
  }
}

class RandomSelectorScreen extends StatefulWidget {
  @override
  _RandomSelectorScreenState createState() => _RandomSelectorScreenState();
}

class _RandomSelectorScreenState extends State<RandomSelectorScreen> with SingleTickerProviderStateMixin {
  List<String> items = [];
  String? selectedItem;
  int _key = 0;
  Color _color1 = const Color.fromARGB(255, 242, 240, 245);
  Color _color2 = const Color.fromARGB(255, 199, 192, 192);
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _loadCSV();
  }

  Future<void> _loadCSV() async {
    final csvString = await rootBundle.loadString('assets/list.csv');
    setState(() {
      items = csvString
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectRandomItem() {
    if (items.isEmpty) return;
    final random = Random();
    setState(() {
      selectedItem = items[random.nextInt(items.length)];
      _key++;
      _color1 = Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.2);
      _color2 = Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(0.2);
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: AnimatedContainer(
        duration: Duration(milliseconds: 1200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_color1, _color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: _loading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      child: Text('하나은행 IT시스템부 단말인프라팀', style: TextStyle(color: Colors.white,
                      shadows: [
                            Shadow(
                              blurRadius: 18.0,
                              color: Colors.black.withOpacity(0.6),
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 150),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Image.asset(
                        'assets/images/ask.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: child,
                        );
                      },
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          selectedItem ?? '오늘의 식당을 골라주세요!',
                          key: ValueKey<int>(_key),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 18.0,
                                color: Colors.black.withOpacity(0.7),
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 8.0,
                                color: _color1.withOpacity(0.7),
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 101, 177, 130),
                        foregroundColor: _color1,
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      onPressed: selectRandomItem,
                      child: Text('어디로 갈까요?',
                      style: TextStyle(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 18.0,
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 8.0,
                              color: _color1.withOpacity(0.5),
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}