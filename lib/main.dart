import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(QuranApp());
}

class QuranApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'HafsSmart_08',
      ),
      home: SurahMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SurahMenuScreen extends StatefulWidget {
  @override
  _SurahMenuScreenState createState() => _SurahMenuScreenState();
}

class _SurahMenuScreenState extends State<SurahMenuScreen> {
  Map<String, List<String>> quranData = {};
  Map<String, dynamic> tafsirData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final String quranJsonString =
          await rootBundle.loadString('lib/data/quran.json');
      final Map<String, dynamic> quranJsonData = json.decode(quranJsonString);

      final String tafsirJsonString = await rootBundle
          .loadString('lib/data/tafsir/ar-tafsir-ibn-kathir.json');
      final Map<String, dynamic> tafsirJsonData = json.decode(tafsirJsonString);

      setState(() {
        quranData = quranJsonData
            .map((key, value) => MapEntry(key, List<String>.from(value)));
        tafsirData = tafsirJsonData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6E3),
      appBar: AppBar(
        title: Text(
          'القرآن الكريم',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'HafsSmart_08',
          ),
        ),
        backgroundColor: Colors.brown[800],
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[600]!),
              ),
            )
          : ListView.builder(
              itemCount: quranData.keys.length,
              itemBuilder: (context, index) {
                String surahName = quranData.keys.elementAt(index);
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahReadScreen(
                            surahName: surahName,
                            ayas: quranData[surahName]!,
                            surahIndex: index + 1,
                            tafsirData: tafsirData,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      surahName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                        fontFamily: 'HafsSmart_08',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SurahReadScreen extends StatefulWidget {
  final String surahName;
  final List<String> ayas;
  final int surahIndex;
  final Map<String, dynamic> tafsirData;

  SurahReadScreen({
    required this.surahName,
    required this.ayas,
    required this.surahIndex,
    required this.tafsirData,
  });

  @override
  _SurahReadScreenState createState() => _SurahReadScreenState();
}

class _SurahReadScreenState extends State<SurahReadScreen> {
  int? selectedAyaIndex;
  int? longPressedAyaIndex;

  void _onAyaLongPress(int ayaIndex) {
    String tafsirKey = "${widget.surahIndex}:${ayaIndex + 1}";
    if (widget.tafsirData.containsKey(tafsirKey)) {
      HapticFeedback.mediumImpact();
      setState(() {
        longPressedAyaIndex = ayaIndex;
      });

      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            longPressedAyaIndex = null;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TafsirScreen(
                surahName: widget.surahName,
                ayaIndex: ayaIndex + 1,
                tafsirText: widget.tafsirData[tafsirKey]['text'],
                ayaText: widget.ayas[ayaIndex],
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String fullText = widget.ayas.join(' ');

    return Scaffold(
      backgroundColor: Color(0xFFFDF6E3),
      appBar: AppBar(
        title: Text(
          widget.surahName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'HafsSmart_08',
          ),
        ),
        backgroundColor: Colors.brown[800],
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: RichText(
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          text: TextSpan(
            children: widget.ayas.asMap().entries.map((entry) {
              int index = entry.key;
              String aya = entry.value;
              bool isLongPressed = longPressedAyaIndex == index;

              return WidgetSpan(
                child: GestureDetector(
                  onLongPress: () => _onAyaLongPress(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLongPressed
                          ? Colors.brown[200]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      aya + " ",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black87,
                        fontFamily: 'HafsSmart_08',
                        height: 1.8,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class TafsirScreen extends StatelessWidget {
  final String surahName;
  final int ayaIndex;
  final String tafsirText;
  final String ayaText;

  TafsirScreen({
    required this.surahName,
    required this.ayaIndex,
    required this.tafsirText,
    required this.ayaText,
  });

  String cleanTafsirText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\[\[.*?\]\]'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6E3),
      appBar: AppBar(
        title: Text(
          'تفسير الآية $ayaIndex من $surahName',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'HafsSmart_08',
          ),
        ),
        backgroundColor: Colors.brown[800],
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'الآية $ayaIndex',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                      fontFamily: 'HafsSmart_08',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    ayaText,
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                      fontFamily: 'HafsSmart_08',
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanTafsirText(tafsirText),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      height: 1.6,
                      fontFamily: 'HafsSmart_08',
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
