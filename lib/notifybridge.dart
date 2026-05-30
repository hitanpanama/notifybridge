import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF080810),
  ));
  runApp(const NotifyBridgeApp());
}

// ── DESIGN TOKENS ─────────────────────────────────────────
class C {
  static const bg = Color(0xFF080810);
  static const surface = Color(0xFF0d0d1a);
  static const surfaceHigh = Color(0xFF12121f);
  static const border = Color(0xFF1c1c2e);
  static const borderBright = Color(0xFF2a2a40);
  static const blue = Color(0xFF4F8EF7);
  static const green = Color(0xFF2ECC8F);
  static const pink = Color(0xFFE050A0);
  static const amber = Color(0xFFF5A623);
  static const purple = Color(0xFF9B72CF);
  static const red = Color(0xFFE05050);
  static const textPrimary = Color(0xFFE8E8F0);
  static const textSecondary = Color(0xFF7070A0);
  static const textMuted = Color(0xFF404060);
}

// ── DATA MODELS ───────────────────────────────────────────
class Rule {
  final int id;
  final String name;
  final String trigger;
  final Color color;
  final String icon;
  final int runs;
  final String lastRun;
  final String target;
  bool enabled;

  Rule({
    required this.id,
    required this.name,
    required this.trigger,
    required this.color,
    required this.icon,
    required this.runs,
    required this.lastRun,
    required this.target,
    required this.enabled,
  });
}

class LogEntry {
  final int id;
  final String rule;
  final String status;
  final String msg;
  final String time;
  final Color color;

  LogEntry({
    required this.id,
    required this.rule,
    required this.status,
    required this.msg,
    required this.time,
    required this.color,
  });
}

class TriggerType {
  final String name;
  final String icon;
  final String desc;
  final Color color;
  final String badge;

  TriggerType({
    required this.name,
    required this.icon,
    required this.desc,
    required this.color,
    required this.badge,
  });
}

// ── MOCK DATA ─────────────────────────────────────────────
final List<Rule> initialRules = [
  Rule(id: 1, name: "Screenshot Auto-Forward", enabled: true, trigger: "file_watcher", color: C.green, icon: "📸", runs: 142, lastRun: "2m ago", target: "Dev Channel"),
  Rule(id: 2, name: "OTP Capture", enabled: true, trigger: "notification", color: C.blue, icon: "🔐", runs: 89, lastRun: "14m ago", target: "Personal"),
  Rule(id: 3, name: "Daily Report", enabled: false, trigger: "scheduler", color: C.amber, icon: "📊", runs: 30, lastRun: "1d ago", target: "Team Group"),
  Rule(id: 4, name: "Webhook Relay", enabled: true, trigger: "webhook", color: C.pink, icon: "🔗", runs: 511, lastRun: "just now", target: "Alerts"),
  Rule(id: 5, name: "App Crash Alert", enabled: false, trigger: "app_event", color: C.purple, icon: "⚡", runs: 7, lastRun: "3d ago", target: "Debug"),
];

final List<LogEntry> logs = [
  LogEntry(id: 1, rule: "Webhook Relay", status: "sent", msg: "POST /hook → Alerts group", time: "00:02", color: C.green),
  LogEntry(id: 2, rule: "OTP Capture", status: "sent", msg: "Notif from BCA Mobile → Personal", time: "00:14", color: C.green),
  LogEntry(id: 3, rule: "Screenshot Auto-Forward", status: "sent", msg: "Screenshot_20250529.png → Dev Channel", time: "00:32", color: C.green),
  LogEntry(id: 4, rule: "Daily Report", status: "skipped", msg: "Rule disabled", time: "00:00", color: C.amber),
  LogEntry(id: 5, rule: "Webhook Relay", status: "retry", msg: "Timeout — retrying (2/3)", time: "01:05", color: C.pink),
  LogEntry(id: 6, rule: "OTP Capture", status: "sent", msg: "Notif from GoPay → Personal", time: "01:22", color: C.green),
  LogEntry(id: 7, rule: "App Crash Alert", status: "error", msg: "Permission denied — Notification Access", time: "02:11", color: C.red),
];

final List<TriggerType> triggers = [
  TriggerType(name: "Notification Listener", icon: "🔔", desc: "Capture any app notification in real-time", color: C.blue, badge: "POPULAR"),
  TriggerType(name: "File Watcher", icon: "📁", desc: "Monitor folders for new or changed files", color: C.green, badge: ""),
  TriggerType(name: "Webhook", icon: "🔗", desc: "Receive HTTP POST from external services", color: C.pink, badge: "DEV"),
  TriggerType(name: "Scheduler", icon: "⏰", desc: "Time-based cron triggers, recurring or one-shot", color: C.amber, badge: ""),
  TriggerType(name: "Manual", icon: "👆", desc: "One-tap trigger from homescreen widget", color: C.purple, badge: ""),
  TriggerType(name: "App Event", icon: "⚡", desc: "Android Intents from third-party apps", color: C.textSecondary, badge: "BETA"),
];

// ── APP ROOT ──────────────────────────────────────────────
class NotifyBridgeApp extends StatelessWidget {
  const NotifyBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotifyBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: C.bg,
        colorScheme: const ColorScheme.dark(primary: C.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

// ── HOME SCREEN ───────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _page = 'dashboard';
  late List<Rule> _rules;

  @override
  void initState() {
    super.initState();
    _rules = List.from(initialRules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Row(
        children: [
          _Sidebar(active: _page, onNav: (p) => setState(() => _page = p), connected: true),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_page) {
      case 'dashboard': return DashboardView(key: const ValueKey('dashboard'), rules: _rules, onToggle: (id, val) => setState(() => _rules.firstWhere((r) => r.id == id).enabled = val));
      case 'rules': return RulesView(key: const ValueKey('rules'), rules: _rules, onToggle: (id, val) => setState(() => _rules.firstWhere((r) => r.id == id).enabled = val));
      case 'logs': return LogsView(key: const ValueKey('logs'));
      case 'triggers': return TriggersView(key: const ValueKey('triggers'));
      case 'settings': return const SettingsView(key: ValueKey('settings'));
      default: return DashboardView(key: const ValueKey('dashboard'), rules: _rules, onToggle: (id, val) => setState(() => _rules.firstWhere((r) => r.id == id).enabled = val));
    }
  }
}

// ── SIDEBAR ───────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final String active;
  final Function(String) onNav;
  final bool connected;

  const _Sidebar({required this.active, required this.onNav, required this.connected});

  static const _nav = [
    {'id': 'dashboard', 'icon': '⬡', 'label': 'Dashboard'},
    {'id': 'rules', 'icon': '◈', 'label': 'Rules'},
    {'id': 'logs', 'icon': '◎', 'label': 'Activity'},
    {'id': 'triggers', 'icon': '▣', 'label': 'Triggers'},
    {'id': 'settings', 'icon': '▤', 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: C.surface,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0x4D4F8EF7), Color(0x332ECC8F)]),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.blue.withOpacity(0.3)),
            ),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(height: 20),
          ..._nav.map((n) => _NavBtn(
            icon: n['icon']!,
            label: n['label']!,
            active: active == n['id'],
            onTap: () => onNav(n['id']!),
          )),
          const Spacer(),
          Container(
            width: 8, height: 8,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? C.green : C.red,
              boxShadow: [BoxShadow(color: (connected ? C.green : C.red).withOpacity(0.6), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44, height: 44,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: active ? C.blue.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? C.blue.withOpacity(0.5) : Colors.transparent),
            boxShadow: active ? [BoxShadow(color: C.blue.withOpacity(0.2), blurRadius: 12)] : null,
          ),
          child: Center(
            child: Text(icon, style: TextStyle(fontSize: 18, color: active ? C.blue : C.textMuted)),
          ),
        ),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────
class Pill extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const Pill({super.key, required this.label, this.color = C.blue, this.size = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }
}

class NBToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const NBToggle({super.key, required this.value, required this.onChanged, this.color = C.green});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 20,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: value ? color.withOpacity(0.2) : C.border,
          border: Border.all(color: value ? color.withOpacity(0.6) : C.borderBright),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? color : C.textMuted,
              boxShadow: value ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)] : null,
            ),
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;
  final String icon;

  const StatCard({super.key, required this.label, required this.value, this.sub, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: C.textSecondary, fontSize: 10)),
            if (sub != null) Text(sub!, style: const TextStyle(color: C.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ── DASHBOARD VIEW ────────────────────────────────────────
class DashboardView extends StatelessWidget {
  final List<Rule> rules;
  final Function(int, bool) onToggle;

  const DashboardView({super.key, required this.rules, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final activeRules = rules.where((r) => r.enabled).length;
    final totalRuns = rules.fold(0, (sum, r) => sum + r.runs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('NotifyBridge', style: TextStyle(color: C.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Your device. Your rules. Your Telegram.', style: TextStyle(color: C.textMuted, fontSize: 12)),
          const SizedBox(height: 24),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: C.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.green.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: C.green, boxShadow: [BoxShadow(color: C.green.withOpacity(0.6), blurRadius: 6)])),
                const SizedBox(width: 8),
                const Text('Engine Running', style: TextStyle(color: C.green, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(width: 12),
                Text('$activeRules rules active', style: const TextStyle(color: C.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              StatCard(label: 'Sent Today', value: '$totalRuns', color: C.blue, icon: '📤'),
              const SizedBox(width: 10),
              StatCard(label: 'Active Rules', value: '$activeRules', color: C.green, icon: '⚙️'),
              const SizedBox(width: 10),
              StatCard(label: 'Failed', value: '0', color: C.red, icon: '❌'),
            ],
          ),
          const SizedBox(height: 24),

          // Rules header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Rules', style: TextStyle(color: C.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              Pill(label: '${rules.length} total'),
            ],
          ),
          const SizedBox(height: 12),

          ...rules.map((rule) => _RuleCard(rule: rule, onToggle: onToggle)),

          const SizedBox(height: 24),

          // Recent log preview
          const Text('Recent Activity', style: TextStyle(color: C.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...logs.take(3).map((log) => _LogRow(entry: log)),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final Rule rule;
  final Function(int, bool) onToggle;

  const _RuleCard({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: C.border),
          right: BorderSide(color: C.border),
          bottom: BorderSide(color: C.border),
          left: BorderSide(color: rule.color, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(rule.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.name, style: const TextStyle(color: C.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Pill(label: rule.trigger, color: rule.color, size: 9),
                      const SizedBox(width: 6),
                      Text('→ ${rule.target}', style: const TextStyle(color: C.textMuted, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                NBToggle(value: rule.enabled, onChanged: (v) => onToggle(rule.id, v), color: rule.color),
                const SizedBox(height: 4),
                Text(rule.lastRun, style: const TextStyle(color: C.textMuted, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: entry.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.rule, style: const TextStyle(color: C.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(entry.msg, style: const TextStyle(color: C.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Pill(label: entry.status, color: entry.color, size: 9),
        ],
      ),
    );
  }
}

// ── RULES VIEW ────────────────────────────────────────────
class RulesView extends StatelessWidget {
  final List<Rule> rules;
  final Function(int, bool) onToggle;

  const RulesView({super.key, required this.rules, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rules', style: TextStyle(color: C.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: C.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: C.blue.withOpacity(0.4)),
                ),
                child: const Text('+ New Rule', style: TextStyle(color: C.blue, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rules.map((rule) => _FullRuleCard(rule: rule, onToggle: onToggle)),
        ],
      ),
    );
  }
}

class _FullRuleCard extends StatelessWidget {
  final Rule rule;
  final Function(int, bool) onToggle;

  const _FullRuleCard({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: C.border),
          right: BorderSide(color: C.border),
          bottom: BorderSide(color: C.border),
          left: BorderSide(color: rule.color, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(rule.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name, style: const TextStyle(color: C.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Pill(label: rule.trigger, color: rule.color, size: 9),
                          const SizedBox(width: 6),
                          Text('→ ${rule.target}', style: const TextStyle(color: C.textMuted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                NBToggle(value: rule.enabled, onChanged: (v) => onToggle(rule.id, v), color: rule.color),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Runs', value: '${rule.runs}', color: rule.color),
                const SizedBox(width: 16),
                _Stat(label: 'Last Run', value: rule.lastRun, color: C.textSecondary),
                const SizedBox(width: 16),
                _Stat(label: 'Status', value: rule.enabled ? 'Active' : 'Paused', color: rule.enabled ? C.green : C.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: C.textMuted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── LOGS VIEW ─────────────────────────────────────────────
class LogsView extends StatelessWidget {
  const LogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activity Log', style: TextStyle(color: C.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              Pill(label: '${logs.length} entries'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: log.color, boxShadow: [BoxShadow(color: log.color.withOpacity(0.5), blurRadius: 6)]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.rule, style: const TextStyle(color: C.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(log.msg, style: const TextStyle(color: C.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Pill(label: log.status, color: log.color, size: 9),
                        const SizedBox(height: 4),
                        Text(log.time, style: const TextStyle(color: C.textMuted, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── TRIGGERS VIEW ─────────────────────────────────────────
class TriggersView extends StatelessWidget {
  const TriggersView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Trigger Types', style: TextStyle(color: C.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Choose how NotifyBridge listens for events', style: TextStyle(color: C.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          ...triggers.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: t.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: t.color.withOpacity(0.3)),
                  ),
                  child: Center(child: Text(t.icon, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.name, style: const TextStyle(color: C.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                          if (t.badge.isNotEmpty) ...[const SizedBox(width: 8), Pill(label: t.badge, color: t.color, size: 9)],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.desc, style: const TextStyle(color: C.textSecondary, fontSize: 11, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.amber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.amber.withOpacity(0.25)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠ Android Notification Access', style: TextStyle(color: C.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Notification Listener requires manual permission.\nSettings → Special App Access → Notification Access → enable NotifyBridge.', style: TextStyle(color: C.textMuted, fontSize: 11, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SETTINGS VIEW ─────────────────────────────────────────
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _tokenCtrl = TextEditingController(text: '5231...XXXX');
  final _chatCtrl = TextEditingController(text: '-100123456789');
  String _apiMode = 'bot_api';
  bool _autoRetry = true;
  bool _localServer = true;
  String _testStatus = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Settings', style: TextStyle(color: C.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),

          // Credentials
          _sectionLabel('TELEGRAM CREDENTIALS'),
          _card(children: [
            _inputField('Bot Token', _tokenCtrl, obscure: true),
            const Divider(color: C.border, height: 1),
            _inputField('Default Chat ID', _chatCtrl),
            const Divider(color: C.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: GestureDetector(
                onTap: () {
                  setState(() => _testStatus = 'testing');
                  Future.delayed(const Duration(seconds: 1), () => setState(() => _testStatus = 'ok'));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: _testStatus == 'ok' ? C.green.withOpacity(0.15) : C.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _testStatus == 'ok' ? C.green.withOpacity(0.5) : C.blue.withOpacity(0.4)),
                  ),
                  child: Text(
                    _testStatus == 'testing' ? 'Testing...' : _testStatus == 'ok' ? '✓ Connected' : 'Test Connection',
                    style: TextStyle(color: _testStatus == 'ok' ? C.green : C.blue, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // API Mode
          _sectionLabel('API MODE'),
          _card(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _apiModeBtn('bot_api', '🤖', 'Bot API', 'Simple — just a token'),
                  const SizedBox(width: 10),
                  _apiModeBtn('client_api', '👤', 'Client API', 'Full access — api_id required'),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // Behavior
          _sectionLabel('BEHAVIOR'),
          _card(children: [
            _toggleRow('Auto Retry', 'Retry failed sends up to 3×', _autoRetry, (v) => setState(() => _autoRetry = v), C.green),
            const Divider(color: C.border, height: 1),
            _toggleRow('Local Webhook Server', 'Listen on localhost:8080 for POST', _localServer, (v) => setState(() => _localServer = v), C.pink),
          ]),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.green.withOpacity(0.2)),
            ),
            child: const Text(
              '🔒 Credentials encrypted with OS Keychain · All data stays on device · Zero external server',
              style: TextStyle(color: C.textMuted, fontSize: 11, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: C.textMuted, fontSize: 10, letterSpacing: 1.5)),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.border)),
    child: Column(children: children),
  );

  Widget _inputField(String label, TextEditingController ctrl, {bool obscure = false}) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: C.textSecondary, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: C.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: C.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.borderBright)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.borderBright)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: C.blue)),
          ),
        ),
      ],
    ),
  );

  Widget _apiModeBtn(String key, String emoji, String label, String sub) {
    final active = _apiMode == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _apiMode = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? C.blue.withOpacity(0.12) : C.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? C.blue.withOpacity(0.5) : C.border),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: active ? C.blue : C.textPrimary, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 3),
              Text(sub, style: const TextStyle(color: C.textMuted, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(String label, String sub, bool value, ValueChanged<bool> onChanged, Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: C.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: C.textMuted, fontSize: 11)),
            ],
          ),
        ),
        NBToggle(value: value, onChanged: onChanged, color: color),
      ],
    ),
  );
}
