# NotifyBridge 🚀
> Your device. Your rules. Your Telegram.

Engine automation Dart yang jalan di Termux —
auto kirim file, notifikasi, dan event ke Telegram.
Zero server. Data 100% di device sendiri.

---

## ✅ Features
- 📁 File Watcher — pantau folder, auto kirim file baru
- ⏰ Scheduler — kirim pesan otomatis jam tertentu
- 🔗 Webhook — terima HTTP POST dari app lain
- 📋 Multi-rule — pantau banyak folder serentak
- 📝 Log file — catat semua aktiviti
- 🔄 Auto-start — jalan otomatis bila Termux dibuka

---

## 📱 Requirements
- Android + Termux
- Termux:Boot (dari F-Droid)
- Dart SDK (`pkg install dart`)
- Bot Telegram (dari @BotFather)

---

## ⚡ Quick Setup

### 1. Install Dart
```bash
pkg update && pkg upgrade
pkg install git curl unzip wget dart
```

### 2. Clone / buat project
```bash
dart create notifybridge
cd notifybridge
```

### 3. Install packages
Edit `pubspec.yaml`, tambah dependencies:
```yaml
dependencies:
  path: ^1.9.0
  http: ^1.2.0
  watcher: ^1.1.0
  shelf: ^1.4.0
  shelf_router: ^1.1.0
```
```bash
dart pub get
```

### 4. Setup config
```bash
nano ~/.notifybridge.conf
```
Isi:
```
BOT_TOKEN=your_bot_token_here
CHAT_ID=your_chat_id_here

SCHEDULE_HOUR=7
SCHEDULE_MINUTE=0
SCHEDULE_MESSAGE=🌅 Selamat pagi! NotifyBridge aktif.

WEBHOOK_PORT=8080

# Rules — tambah ikut keperluan
RULE_1_FOLDER=/storage/emulated/0/DCIM/Screenshots
RULE_1_CHAT_ID=your_chat_id_here
RULE_1_MESSAGE=📸 Screenshot baru!

RULE_2_FOLDER=/storage/emulated/0/Download
RULE_2_CHAT_ID=your_chat_id_here
RULE_2_MESSAGE=📥 File download baru!

RULE_3_FOLDER=/storage/emulated/0/DCIM/Camera
RULE_3_CHAT_ID=your_chat_id_here
RULE_3_MESSAGE=📷 Foto baru dari Camera!

RULE_4_FOLDER=/storage/emulated/0/DCIM/Video
RULE_4_CHAT_ID=your_chat_id_here
RULE_4_MESSAGE=🎬 Video baru!

RULE_5_FOLDER=/storage/emulated/0/Download/Quick Share
RULE_5_CHAT_ID=your_chat_id_here
RULE_5_MESSAGE=⚡ File baru dari Quick Share!
```

### 5. Jalankan
```bash
dart run
```

---

## 🔄 Auto-start (Termux:Boot)
```bash
mkdir -p ~/.termux/boot
nano ~/.termux/boot/notifybridge.sh
```
Isi:
```bash
#!/data/data/com.termux/files/usr/bin/bash
cd ~/notifybridge
dart run >> ~/notifybridge.log 2>&1
```
```bash
chmod +x ~/.termux/boot/notifybridge.sh
```

---

## 🔗 Webhook API

### Kirim pesan
```bash
curl -X POST http://localhost:8080/send \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello dari webhook!"}'
```

### Kirim ke chat tertentu
```bash
curl -X POST http://localhost:8080/send \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello!", "chat_id":"123456789"}'
```

### Cek status
```bash
curl http://localhost:8080/status
```

---

## 📝 Cek Log
```bash
cat ~/notifybridge.log
tail -f ~/notifybridge.log
```

---

## 📁 Folder Rules Aktif
| Rule | Folder | Pesan |
|------|--------|-------|
| 1 | Screenshots | 📸 Screenshot baru! |
| 2 | Download | 📥 File download baru! |
| 3 | Camera | 📷 Foto baru dari Camera! |
| 4 | Video | 🎬 Video baru! |
| 5 | Quick Share | ⚡ File baru dari Quick Share! |

---

## 🗺️ Roadmap
- [x] Dart CLI engine
- [x] File Watcher multi-rule
- [x] Scheduler
- [x] Webhook receiver
- [x] Log file
- [x] Auto-start
- [ ] Flutter APK (bila ada laptop)
- [ ] Dashboard UI
- [ ] Rule builder visual
- [ ] Notification Listener

---

## 🔐 Keselamatan
- Token disimpan di `~/.notifybridge.conf` — tidak dalam kod
- Data tidak keluar ke mana-mana server
- Semua proses berlaku di device sendiri

---

*NotifyBridge — Blueprint v1.0 | Dart Edition*A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.
