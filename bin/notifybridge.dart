import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:watcher/watcher.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ── Logger ────────────────────────────────────────────────
late File logFile;

void log(String status, String pesan) {
  final now = DateTime.now();
  final waktu =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  final baris = '[$waktu] [$status] $pesan';
  print(baris);
  logFile.writeAsStringSync('$baris\n', mode: FileMode.append);
}

// ── Load config ───────────────────────────────────────────
Map<String, String> loadConfig() {
  final home = Platform.environment['HOME'] ?? '';
  final file = File('$home/.notifybridge.conf');
  if (!file.existsSync()) {
    print('✗ Config tidak ditemukan');
    exit(1);
  }
  final config = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final parts = line.split('=');
    if (parts.length >= 2) {
      config[parts[0].trim()] = parts.sublist(1).join('=').trim();
    }
  }
  return config;
}

// ── Rule model ────────────────────────────────────────────
class Rule {
  final String name;
  final String folder;
  final String chatId;
  final String message;

  Rule({
    required this.name,
    required this.folder,
    required this.chatId,
    required this.message,
  });
}

List<Rule> loadRules(Map<String, String> config) {
  final rules = <Rule>[];
  var i = 1;
  while (true) {
    final folder = config['RULE_${i}_FOLDER'];
    if (folder == null) break;
    rules.add(Rule(
      name: 'Rule $i',
      folder: folder,
      chatId: config['RULE_${i}_CHAT_ID'] ?? config['CHAT_ID'] ?? '',
      message: config['RULE_${i}_MESSAGE'] ?? '📄 File baru!',
    ));
    i++;
  }
  return rules;
}

// ── Telegram ──────────────────────────────────────────────
late String token;
late String defaultChatId;

Future<void> kirimPesan(String pesan, {String? chatId}) async {
  try {
    final url = Uri.parse(
        'https://api.telegram.org/bot$token/sendMessage');
    final res = await http.post(url, body: {
      'chat_id': chatId ?? defaultChatId,
      'text': pesan,
    });
    if (res.statusCode == 200) {
      log('OK', 'Pesan terkirim ke ${chatId ?? defaultChatId}');
    } else {
      log('ERROR', 'Gagal: ${res.statusCode}');
    }
  } catch (e) {
    log('ERROR', 'Exception: $e');
  }
}

Future<void> kirimFile(String filePath, {String? chatId}) async {
  try {
    final url = Uri.parse(
        'https://api.telegram.org/bot$token/sendDocument');
    final request = http.MultipartRequest('POST', url);
    request.fields['chat_id'] = chatId ?? defaultChatId;
    request.files.add(
        await http.MultipartFile.fromPath('document', filePath));
    final res = await request.send();
    if (res.statusCode == 200) {
      log('OK', 'File terkirim: $filePath');
    } else {
      log('ERROR', 'Gagal kirim file');
    }
  } catch (e) {
    log('ERROR', 'Exception kirim file: $e');
  }
}

// ── Scheduler ─────────────────────────────────────────────
void startScheduler(int hour, int minute, String message) {
  log('INFO', 'Scheduler aktif: jam $hour:${minute.toString().padLeft(2, '0')}');
  Timer.periodic(Duration(minutes: 1), (timer) async {
    final now = DateTime.now();
    if (now.hour == hour && now.minute == minute) {
      log('SCHED', 'Scheduler triggered!');
      await kirimPesan(message);
    }
  });
}

// ── Multi-rule Watcher ────────────────────────────────────
void startRules(List<Rule> rules) {
  if (rules.isEmpty) {
    log('INFO', 'Tiada rule dikonfigurasi');
    return;
  }
  for (final rule in rules) {
    if (!Directory(rule.folder).existsSync()) {
      log('ERROR', '${rule.name}: folder tidak ditemukan: ${rule.folder}');
      continue;
    }
    log('INFO', '${rule.name} aktif → ${rule.folder}');
    final watcher = DirectoryWatcher(rule.folder);
    watcher.events.listen((event) async {
      if (event.type == ChangeType.ADD) {
        log('FILE', '${rule.name}: file baru: ${event.path}');
        await kirimPesan(
          '${rule.message}\n📄 ${event.path}',
          chatId: rule.chatId,
        );
        await kirimFile(event.path, chatId: rule.chatId);
      }
    });
  }
  log('INFO', '${rules.length} rule aktif ✓');
}

// ── Webhook Server ────────────────────────────────────────
Future<void> startWebhook(int port) async {
  final router = Router();

  router.post('/send', (Request req) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final pesan = data['message'] as String? ?? 'No message';
      final chatId = data['chat_id'] as String?;
      log('WEBHOOK', 'POST /send: $pesan');
      await kirimPesan('🔗 Webhook:\n$pesan', chatId: chatId);
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'status': 'error', 'message': '$e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  router.get('/status', (Request req) {
    return Response.ok(
      jsonEncode({'status': 'running', 'app': 'NotifyBridge'}),
      headers: {'content-type': 'application/json'},
    );
  });

  final server = await shelf_io.serve(router.call, '0.0.0.0', port);
  log('INFO', 'Webhook server jalan di port ${server.port}');
}

// ── Main ──────────────────────────────────────────────────
void main() async {
  final home = Platform.environment['HOME'] ?? '';
  logFile = File('$home/notifybridge.log');
  log('START', '🚀 NotifyBridge starting...');

  final config = loadConfig();
  token = config['BOT_TOKEN'] ?? '';
  defaultChatId = config['CHAT_ID'] ?? '';
  final schedHour = int.tryParse(config['SCHEDULE_HOUR'] ?? '') ?? -1;
  final schedMinute = int.tryParse(config['SCHEDULE_MINUTE'] ?? '') ?? 0;
  final schedMessage = config['SCHEDULE_MESSAGE'] ?? '🔔 Reminder';
  final webhookPort = int.tryParse(config['WEBHOOK_PORT'] ?? '') ?? 8080;

  if (token.isEmpty || defaultChatId.isEmpty) {
    log('ERROR', 'Config tidak lengkap');
    exit(1);
  }

  log('INFO', 'Config loaded ✓');

  // Load & start rules
  final rules = loadRules(config);
  startRules(rules);

  // Scheduler
  if (schedHour >= 0) startScheduler(schedHour, schedMinute, schedMessage);

  // Webhook
  await startWebhook(webhookPort);

  await kirimPesan(
    '✅ NotifyBridge aktif!\n'
    '📋 ${rules.length} rule loaded\n'
    '⏰ Scheduler: $schedHour:${schedMinute.toString().padLeft(2, '0')}\n'
    '🔗 Webhook: port $webhookPort',
  );

  await Future.delayed(Duration(days: 365));
}
