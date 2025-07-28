import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'القرآن الكريم',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFFDF6E3),
      ),
      home: const SurahMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SurahMenuScreen extends StatefulWidget {
  const SurahMenuScreen({super.key});

  @override
  State<SurahMenuScreen> createState() => _SurahMenuScreenState();
}

class _SurahMenuScreenState extends State<SurahMenuScreen> {
  List<Map<String, dynamic>> surahs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSurahs();
  }

  Future<void> loadSurahs() async {
    try {
      final String quranJsonString =
          await rootBundle.loadString('lib/data/quran.json');
      final List<dynamic> quranData = json.decode(quranJsonString);

      if (mounted) {
        setState(() {
          surahs = List<Map<String, dynamic>>.from(quranData);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'القرآن الكريم',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surah = surahs[index];
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahReadScreen(
                            surah: surah,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      surah['name']['ar'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    subtitle: Text(
                      '${surah['verses_count']} آية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown[600],
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
  const SurahReadScreen({super.key, required this.surah});

  final Map<String, dynamic> surah;

  @override
  State<SurahReadScreen> createState() => _SurahReadScreenState();
}

class _SurahReadScreenState extends State<SurahReadScreen> {
  Map<String, dynamic> tafsirData = {};
  bool isLoading = true;
  int? selectedAyaIndex;
  Offset? buttonPosition;

  @override
  void initState() {
    super.initState();
    loadTafsirData();
  }

  Future<void> loadTafsirData() async {
    try {
      final String tafsirJsonString = await rootBundle
          .loadString('lib/data/tafsir/ar-tafsir-ibn-kathir.json');
      final Map<String, dynamic> allTafsirData = json.decode(tafsirJsonString);

      if (mounted) {
        setState(() {
          tafsirData = allTafsirData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onAyaLongPress(int ayaNumber, LongPressStartDetails details) {
    String tafsirKey = "${widget.surah['number']}:$ayaNumber";
    if (tafsirData.containsKey(tafsirKey)) {
      HapticFeedback.mediumImpact();
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      setState(() {
        selectedAyaIndex = ayaNumber;
        buttonPosition = overlay.globalToLocal(details.globalPosition);
      });
    }
  }

  void _hideButton() {
    if (selectedAyaIndex != null) {
      setState(() {
        selectedAyaIndex = null;
        buttonPosition = null;
      });
    }
  }

  void _navigateToTafsir() {
    if (selectedAyaIndex == null) return;

    final int ayaNumber = selectedAyaIndex!;
    String tafsirKey = "${widget.surah['number']}:$ayaNumber";

    final verse = widget.surah['verses'].firstWhere(
      (v) => v['number'] == ayaNumber,
    );

    _hideButton();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TafsirScreen(
          surahName: widget.surah['name']['ar'],
          ayaNumber: ayaNumber,
          tafsirText: tafsirData[tafsirKey]['text'],
          ayaText: verse['text']['ar'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.surah['name']['ar'],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
          : GestureDetector(
              onTap: _hideButton,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.black87,
                          height: 1.8,
                          fontFamily: 'Amiri',
                        ),
                        children: widget.surah['verses'].map<TextSpan>((verse) {
                          final ayaNumber = verse['number'];
                          final ayaText = verse['text']['ar'];
                          final isSelected = selectedAyaIndex == ayaNumber;

                          return TextSpan(
                            text: '$ayaText ﴿$ayaNumber﴾ ',
                            style: TextStyle(
                              color: isSelected ? Colors.brown : Colors.black87,
                              backgroundColor: isSelected ? Colors.brown : null,
                            ),
                            recognizer: LongPressGestureRecognizer()
                              ..onLongPressStart = (details) =>
                                  _onAyaLongPress(ayaNumber, details),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (selectedAyaIndex != null && buttonPosition != null)
                    Positioned(
                      top: buttonPosition!.dy - 60,
                      left: buttonPosition!.dx - 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _navigateToTafsir,
                        child: const Text('التفسير'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class TafsirScreen extends StatelessWidget {
  const TafsirScreen({
    super.key,
    required this.surahName,
    required this.ayaNumber,
    required this.tafsirText,
    required this.ayaText,
  });

  final String surahName;
  final int ayaNumber;
  final String tafsirText;
  final String ayaText;

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
      appBar: AppBar(
        title: Text(
          'تفسير الآية $ayaNumber من $surahName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.brown[800],
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.brown[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.brown[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'الآية $ayaNumber',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ayaText,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.black87,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
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
                    'التفسير',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cleanTafsirText(tafsirText),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      height: 1.6,
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
