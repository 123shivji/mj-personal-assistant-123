import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(const MJApp());

class MJApp extends StatelessWidget {
  const MJApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'MJ AI',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF777CFF), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF090D1B),
      useMaterial3: true,
    ),
    home: const AssistantScreen(),
  );
}

class ChatLine {
  ChatLine(this.text, this.fromMJ);
  final String text;
  final bool fromMJ;
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final TextEditingController input = TextEditingController();
  final List<ChatLine> chat = [ChatLine('नमस्ते! मैं MJ हूँ ❤️ मुझसे कुछ भी बात करो।', true)];

  // Android phone: replace 127.0.0.1 with your computer's LAN IP.
  static const String apiUrl = 'http://127.0.0.1:8000/chat';

  bool speechReady = false, listening = false, wakeMode = false, busy = false;
  String status = 'मुझसे बात करने के लिए माइक दबाएँ';

  @override
  void initState() {
    super.initState();
    setupVoice();
  }

  Future<void> setupVoice() async {
    await tts.setLanguage('hi-IN');
    await tts.setSpeechRate(0.46);
    await tts.setPitch(1.08);
    await tts.setVolume(1);
    speechReady = await speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'notListening') {
          setState(() => listening = false);
          if (wakeMode && !busy) {
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted && wakeMode && !busy) startListening();
            });
          }
        }
      },
      onError: (e) {
        if (mounted) setState(() { listening = false; status = 'Speech error: ${e.errorMsg}'; });
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> startListening() async {
    if (!speechReady || busy || listening) return;
    setState(() { listening = true; status = wakeMode ? '“Hey MJ” बोलें…' : 'मैं सुन रही हूँ…'; });
    await speech.listen(
      localeId: 'hi_IN',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      onResult: (r) {
        final words = r.recognizedWords.trim();
        if (words.isEmpty || !mounted) return;
        if (wakeMode) {
          final lower = words.toLowerCase();
          final i = lower.indexOf('hey mj');
          final hi = lower.indexOf('हे एम जे');
          if (i >= 0 || hi >= 0) {
            final start = i >= 0 ? i + 6 : hi + 8;
            final command = words.substring(start).trim();
            setState(() => status = 'हाँ, मैं सुन रही हूँ ❤️');
            if (command.isNotEmpty && r.finalResult) {
              speech.stop();
              handleCommand(command);
            }
          }
        } else if (r.finalResult) {
          speech.stop();
          handleCommand(words);
        }
      },
    );
  }

  Future<void> toggleWake() async {
    if (!speechReady) await setupVoice();
    setState(() { wakeMode = !wakeMode; status = wakeMode ? 'Wake mode चालू — “Hey MJ” कहें' : 'Wake mode बंद'; });
    if (wakeMode) { startListening(); } else { speech.stop(); }
  }

  Future<void> handleCommand(String text) async {
    if (text.trim().isEmpty || busy) return;
    setState(() { busy = true; chat.add(ChatLine(text, false)); status = 'MJ सोच रही है…'; });
    input.clear();
    String answer;
    try {
      final response = await http.post(Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text})).timeout(const Duration(seconds: 35));
      answer = response.statusCode == 200
        ? (jsonDecode(response.body)['reply'] ?? '').toString()
        : 'माफ़ करना, अभी AI सर्वर से जवाब नहीं मिला।';
    } catch (_) {
      answer = 'मैं तुम्हारी बात सुन पाई, लेकिन AI सर्वर से कनेक्शन नहीं हुआ। पहले backend चालू करो।';
    }
    if (!mounted) return;
    setState(() { chat.add(ChatLine(answer, true)); busy = false; status = wakeMode ? '“Hey MJ” कहकर बुलाओ ❤️' : 'मैं सुनने के लिए तैयार हूँ'; });
    await tts.speak(answer);
    if (wakeMode && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      startListening();
    }
  }

  @override
  void dispose() { speech.stop(); tts.stop(); input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        CircleAvatar(backgroundColor: Color(0xFF4549A8), child: Icon(Icons.auto_awesome, color: Colors.white)),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MJ AI', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Your personal companion', style: TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      ]),
      actions: [IconButton(tooltip: 'Hey MJ wake mode', onPressed: toggleWake,
        icon: Icon(wakeMode ? Icons.hearing : Icons.hearing_disabled,
          color: wakeMode ? Colors.greenAccent : Colors.white70))],
    ),
    body: Column(children: [
      const SizedBox(height: 12),
      Container(width: 116, height: 116,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF3D56B5), Color(0xFF9B5DE5)]),
          boxShadow: [BoxShadow(color: const Color(0xFF746BFF).withOpacity(.35), blurRadius: 35, spreadRadius: 8)]),
        child: const Icon(Icons.face_3_rounded, size: 70, color: Colors.white)),
      const SizedBox(height: 10),
      Text(status, style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 10),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: chat.length,
        itemBuilder: (context, index) {
          final line = chat[index];
          return Align(alignment: line.fromMJ ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(constraints: const BoxConstraints(maxWidth: 520),
              margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: line.fromMJ ? const Color(0xFF202747) : const Color(0xFF4549A8),
                borderRadius: BorderRadius.circular(18)),
              child: Text(line.text, style: const TextStyle(fontSize: 15, height: 1.4))));
        })),
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Row(children: [
          IconButton.filled(onPressed: listening ? speech.stop : startListening,
            icon: Icon(listening ? Icons.stop : Icons.mic)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: input, onSubmitted: handleCommand,
            decoration: InputDecoration(hintText: 'MJ से कुछ कहो…', filled: true,
              fillColor: const Color(0xFF171D34),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
          IconButton(onPressed: busy ? null : () => handleCommand(input.text), icon: const Icon(Icons.send_rounded)),
        ])),
      Padding(padding: const EdgeInsets.only(bottom: 8),
        child: Text(wakeMode ? 'Wake mode: ON • “Hey MJ”' : 'Wake mode: OFF • ऊपर hearing बटन से चालू करें',
          style: const TextStyle(fontSize: 11, color: Colors.white38))),
    ]),
  );
}
