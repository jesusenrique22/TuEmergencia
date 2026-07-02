import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_realtime.dart';
import '../theme/app_colors.dart';
import 'dev_tools_config.dart';
import 'gateway_debug_diagnostics.dart';
import 'realtime_debug_log.dart';

/// Panel de diagnóstico de gateway / Socket.IO (solo debug).
class GatewayDebugPage extends StatefulWidget {
  const GatewayDebugPage({super.key});

  @override
  State<GatewayDebugPage> createState() => _GatewayDebugPageState();
}

class _GatewayDebugPageState extends State<GatewayDebugPage> {
  final _log = RealtimeDebugLog.instance;
  List<DiagnosticLine> _diagnostics = [];
  bool _running = false;
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _log.log('DebugUI', 'Panel abierto');
    _runDiagnostics();
    _log.onUpdate.listen((_) {
      if (mounted && _autoRefresh) setState(() {});
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    try {
      final lines = await GatewayDebugDiagnostics.runFullSuite();
      if (mounted) setState(() => _diagnostics = lines);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  List<RealtimeDebugEntry> get _callEntries => _log.entries
      .where((e) => e.tag == 'Call' || e.tag == 'WebRTC')
      .toList();

  Future<void> _copyReport() async {
    final buffer = StringBuffer()
      ..writeln('=== TuEmergencia — Gateway debug ===')
      ..writeln('Generado: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('--- Diagnóstico ---');
    for (final line in _diagnostics) {
      final mark = line.ok == null ? '' : (line.ok! ? ' [OK]' : ' [FAIL]');
      buffer.writeln('${line.label}: ${line.value}$mark');
    }
    buffer.writeln();
    if (_callEntries.isNotEmpty) {
      buffer
        ..writeln('--- Llamadas (Call / WebRTC) ---')
        ..writeln(
          _callEntries.map((e) => e.formatLine()).join('\n\n'),
        )
        ..writeln();
    }
    buffer
      ..writeln('--- Log completo ---')
      ..writeln(_log.exportText());

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!DevToolsConfig.enabled) {
      return const Scaffold(
        body: Center(child: Text('Panel debug no disponible en este build')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Debug realtime'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Diagnóstico', icon: Icon(Icons.medical_services_outlined)),
              Tab(text: 'Log', icon: Icon(Icons.terminal_rounded)),
              Tab(text: 'Llamadas', icon: Icon(Icons.videocam_outlined)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Copiar informe',
              onPressed: _copyReport,
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: 'Limpiar log',
              onPressed: () {
                _log.clear();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _running ? null : _runDiagnostics,
          icon: _running
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: Text(_running ? 'Probando…' : 'Ejecutar pruebas'),
        ),
        body: TabBarView(
          children: [
            _DiagnosticsTab(lines: _diagnostics, running: _running),
            _LogTab(
              entries: _log.entries,
              autoRefresh: _autoRefresh,
              onAutoRefreshChanged: (v) => setState(() => _autoRefresh = v),
              onReconnect: () {
                AppRealtime.chatSocket.resetAuthState();
                unawaited(AppRealtime.connectIfNeeded());
                _log.log('DebugUI', 'Reconexión manual solicitada');
              },
            ),
            _CallLogTab(entries: _callEntries),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsTab extends StatelessWidget {
  const _DiagnosticsTab({required this.lines, required this.running});

  final List<DiagnosticLine> lines;
  final bool running;

  @override
  Widget build(BuildContext context) {
    if (running && lines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Backend :3000, gateway :3001. Las llamadas usan el socket para señalización '
              '(invite/offer/answer/ICE) y WebRTC P2P para audio/video. '
              'Pestaña Llamadas: eventos en vivo. TURN en .env mejora conexiones entre redes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...lines.map((line) => _DiagnosticTile(line: line)),
      ],
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({required this.line});

  final DiagnosticLine line;

  @override
  Widget build(BuildContext context) {
    final Color? iconColor = switch (line.ok) {
      true => Colors.green.shade700,
      false => Colors.red.shade700,
      null => null,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          switch (line.ok) {
            true => Icons.check_circle_rounded,
            false => Icons.error_rounded,
            null => Icons.info_outline_rounded,
          },
          color: iconColor,
        ),
        title: Text(
          line.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SelectableText(line.value, style: const TextStyle(fontSize: 12)),
        ),
        isThreeLine: line.value.length > 48,
      ),
    );
  }
}

class _LogTab extends StatelessWidget {
  const _LogTab({
    required this.entries,
    required this.autoRefresh,
    required this.onAutoRefreshChanged,
    required this.onReconnect,
  });

  final List<RealtimeDebugEntry> entries;
  final bool autoRefresh;
  final ValueChanged<bool> onAutoRefreshChanged;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${entries.length} eventos (más recientes arriba)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReconnect,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reconectar'),
                ),
                FilterChip(
                  label: const Text('Auto'),
                  selected: autoRefresh,
                  onSelected: onAutoRefreshChanged,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('Sin eventos aún'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return _LogTile(entry: e);
                  },
                ),
        ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final RealtimeDebugEntry entry;

  Color _levelColor() => switch (entry.level) {
        RealtimeDebugLevel.error => Colors.red.shade800,
        RealtimeDebugLevel.warn => Colors.orange.shade900,
        RealtimeDebugLevel.success => Colors.green.shade800,
        RealtimeDebugLevel.info => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SelectableText(
          entry.formatLine(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.35,
            color: _levelColor(),
          ),
        ),
      ),
    );
  }
}

class _CallLogTab extends StatelessWidget {
  const _CallLogTab({required this.entries});

  final List<RealtimeDebugEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              entries.isEmpty
                  ? 'Sin eventos de llamada aún — inicia o recibe una llamada desde Mensajes'
                  : '${entries.length} eventos Call/WebRTC (más recientes arriba)',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Flujo esperado:\n'
                      'call:invite → call:accept → call:offer → call:answer → ICE → Peer conectado',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: entries.length,
                  itemBuilder: (_, i) => _LogTile(entry: entries[i]),
                ),
        ),
      ],
    );
  }
}
