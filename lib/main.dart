import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:window_size/window_size.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  setWindowTitle('하나랜덤식당');
  DesktopWindow.setWindowSize(Size(480, 740));
  //FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  FlutterNativeSplash.remove();
  runApp(RandomSelectorApp());
}

Future<String> fetchCsvData(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      print('Failed to fetch CSV: ${response.statusCode}');
      return ''; // Or throw an error
    }
  } catch (e) {
    print('Error fetching CSV: $e');
    return ''; // Or throw an error
  }
}

class RandomSelectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: '명동 식당고르기', home: RandomSelectorScreen());
  }
}

class RandomSelectorScreen extends StatefulWidget {
  final String csvUrl =
      'https://raw.githubusercontent.com/rl544/HanaRandomFood/refs/heads/main/assets/list.csv'; // Replace with the actual URL

  @override
  _RandomSelectorScreenState createState() => _RandomSelectorScreenState();
}

class _RandomSelectorScreenState extends State<RandomSelectorScreen>
    with SingleTickerProviderStateMixin {
  List<String> items = [];
  List<String> _csvData = []; // List<List<dynamic>> _csvData = [];
  List<Map<String, dynamic>> _csvDataWithHeader = [];
  // List<dynamic>? selectedItem;
  String? selectedItem;
  int _key = 0;
  Color _color1 = const Color.fromARGB(255, 242, 240, 245);
  Color _color2 = const Color.fromARGB(255, 199, 192, 192);
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _loadCsvData(); // from Web
    // _loadCSV(); // from internal
  }

  Future<void> _loadCsvData() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });
    final csvString = await fetchCsvData(widget.csvUrl);
    if (csvString.isNotEmpty) {
      setState(() {
        // _csvData = parseCsv(csvString);
        _csvData = parseLCsv(csvString);
        _csvDataWithHeader = parseCsvWithHeader(csvString);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _errorMessage = 'Failed to load CSV data.';
      });
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: Text('CSV Data from Web')),
  //     body:
  //         _loading
  //             ? Center(child: CircularProgressIndicator())
  //             : _errorMessage.isNotEmpty
  //             ? Center(child: Text(_errorMessage))
  //             : SingleChildScrollView(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     'Raw CSV Data:',
  //                     style: TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                   for (var row in _csvData) Text(row.join(', ')),
  //                   SizedBox(height: 20),
  //                   Text(
  //                     'CSV Data with Header:',
  //                     style: TextStyle(fontWeight: FontWeight.bold),
  //                   ),
  //                   if (_csvDataWithHeader.isNotEmpty)
  //                     for (var row in _csvDataWithHeader) Text(row.toString()),
  //                   if (_csvDataWithHeader.isEmpty && _csvData.isNotEmpty)
  //                     Text('No header row detected (using basic parsing).'),
  //                   if (_csvData.isEmpty && _errorMessage.isEmpty)
  //                     Text('No CSV data loaded yet.'),
  //                 ],
  //               ),
  //             ),
  //   );
  // }

  Future<void> _loadCSV() async {
    final csvString = await rootBundle.loadString('assets/list.csv');
    setState(() {
      items = parseLCsv(csvString);
      _loading = false;
    });
  }

  List<String> parseLCsv(String csvString) {
    final List<String> ans =
        csvString
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    return ans;
  }

  List<List<dynamic>> parseCsv(String csvString) {
    final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter()
        .convert(csvString);
    return rowsAsListOfValues;
  }

  List<Map<String, dynamic>> parseCsvWithHeader(String csvString) {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvString,
    );
    if (rows.isEmpty) {
      return [];
    }
    final List<String> header =
        rows.first.map((item) => item.toString()).toList();
    final List<Map<String, dynamic>> data = [];
    for (int i = 1; i < rows.length; i++) {
      final Map<String, dynamic> rowData = {};
      for (int j = 0; j < header.length; j++) {
        rowData[header[j]] = rows[i][j];
      }
      data.add(rowData);
    }
    return data;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectRandomItem() {
    if (_csvData.isEmpty) return; // _csvData items
    final random = Random();
    setState(() {
      selectedItem = _csvData[random.nextInt(_csvData.length)];
      _key++;
      _color1 = Color(
        (random.nextDouble() * 0xFFFFFF).toInt(),
      ).withOpacity(0.2);
      _color2 = Color(
        (random.nextDouble() * 0xFFFFFF).toInt(),
      ).withOpacity(0.2);
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
          child:
              _loading
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(
                          '하나은행 IT시스템부 단말인프라팀',
                          style: TextStyle(
                            color: Colors.white,
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
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
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
                          backgroundColor: const Color.fromARGB(
                            255,
                            101,
                            177,
                            130,
                          ),
                          foregroundColor: _color1,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: selectRandomItem,
                        child: Text(
                          '어디로 갈까요?',
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
