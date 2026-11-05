# MJ – Personal AI Voice Assistant

यह Android + Windows 11 के लिए Flutter starter project है। इसमें चैट UI,
speech-to-text, text-to-speech और Python AI backend शामिल हैं।

## जरूरी बातें
- यह शुरुआती project foundation है; production-ready app नहीं।
- “Hey MJ” wake mode ऐप खुले रहने और speech recognition सक्रिय रहने पर काम करने की कोशिश करता है।
- Android में स्क्रीन लॉक/ऐप बंद होने पर हमेशा सुनने की सुविधा शामिल नहीं है। उसके लिए अलग foreground service और dedicated wake-word engine (जैसे Porcupine) integrate और test करना होगा।
- Speech recognition और महिला हिंदी आवाज़ की उपलब्धता device/OS पर निर्भर है। OS settings में Hindi female voice install/select करें।
- API key केवल backend की `.env` फाइल में रखें; Flutter app में न डालें।

## 1. Flutter तैयार करें
Flutter SDK install करें और `flutter doctor` चलाएँ।
Windows build के लिए Visual Studio 2022 में **Desktop development with C++** workload चाहिए।
Android build के लिए Android Studio और Android SDK चाहिए।

## 2. Flutter project scaffold बनाएं
इस folder में terminal खोलें:
```bash
flutter create --platforms=android,windows .
flutter pub get
```
अगर scaffold files overwrite हों, तो इस ZIP के `lib/main.dart` और `pubspec.yaml` रखें।

## 3. AI backend चलाएं (Windows 11)
```powershell
cd backend
py -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```
`.env` खोलकर अपनी OpenAI API key डालें, फिर:
```powershell
uvicorn main:app --host 0.0.0.0 --port 8000
```
Health check: `http://127.0.0.1:8000/health`

## 4. Windows app चलाएं
दूसरी terminal में project root:
```powershell
flutter run -d windows
```

## 5. Android पर चलाएं
फोन और कंप्यूटर एक ही Wi-Fi पर हों। कंप्यूटर का IPv4 पता `ipconfig` से देखें।
`lib/main.dart` में `apiUrl` बदलें:
`http://YOUR-PC-IP:8000/chat`
उदाहरण: `http://192.168.1.20:8000/chat`
Windows Firewall में private network पर port 8000 की अनुमति दें। फिर:
```bash
flutter run -d android
```
फोन पर microphone permission स्वीकार करें।

## 6. APK बनाएं
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## Wake word
ऊपर दाईं ओर hearing icon से wake mode चालू करें और “Hey MJ” बोलें।
Speech recognition engine अलग-अलग devices पर अलग व्यवहार कर सकता है। विश्वसनीय
always-on wake word के लिए dedicated engine को Android और Windows पर integrate/test करना होगा।

## सुरक्षा
यह demo backend authentication के बिना है; public internet पर expose न करें।
Production के लिए authentication, rate limiting, HTTPS, per-user chat storage और data deletion controls जोड़ें।
इस demo की chat history backend process memory में रहती है और server restart पर मिट जाती है।
