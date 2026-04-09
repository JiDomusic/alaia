import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class BloqueosTab extends StatefulWidget {
  const BloqueosTab({super.key});

  @override
  State<BloqueosTab> createState() => _BloqueosTabState();
}

class _BloqueosTabState extends State<BloqueosTab> {
  final _svc = SupabaseService.instance;
  List<Map<String, dynamic>> _bloqueos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarBloqueos();
  }

  Future<void> _cargarBloqueos() async {
    setState(() => _cargando = true);
    try {
      _bloqueos = await _svc.loadBloqueos(desde: DateTime.now().subtract(const Duration(days: 7)));
      if (mounted) setState(() => _cargando = false);
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _nuevoBloqueo() async {
    DateTime fecha = DateTime.now();
    final inicioCtrl = TextEditingController(text: '');
    final finCtrl = TextEditingController(text: '');
    final motivoCtrl = TextEditingController();
    bool diaCompleto = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Nuevo Bloqueo'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(fecha)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDState(() => fecha = picked);
                  },
                ),
                SwitchListTile(
                  title: const Text('Día completo'),
                  value: diaCompleto,
                  onChanged: (v) => setDState(() => diaCompleto = v),
                ),
                if (!diaCompleto) ...[
                  const SizedBox(height: 8),
                  TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Hora inicio (ej: 09:00)')),
                  const SizedBox(height: 12),
                  TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Hora fin (ej: 10:00)')),
                ],
                const SizedBox(height: 12),
                TextField(controller: motivoCtrl, decoration: const InputDecoration(labelText: 'Motivo')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _svc.createBloqueo({
                    'fecha': DateFormat('yyyy-MM-dd').format(fecha),
                    'hora_inicio': diaCompleto ? null : inicioCtrl.text,
                    'hora_fin': diaCompleto ? null : finCtrl.text,
                    'dia_completo': diaCompleto,
                    'motivo': motivoCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  await _cargarBloqueos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _cargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Bloqueos', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _nuevoBloqueo,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_bloqueos.isEmpty)
                  const Center(child: Text('Sin bloqueos'))
                else
                  ..._bloqueos.map((b) {
                    final diaCompleto = b['dia_completo'] == true;
                    final fecha = b['fecha'] ?? '';
                    final inicio = b['hora_inicio']?.toString().substring(0, 5) ?? '';
                    final fin = b['hora_fin']?.toString().substring(0, 5) ?? '';
                    final motivo = b['motivo'] ?? '';

                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.block, color: AppConfig.colorPendiente),
                        title: Text(
                          '$fecha ${diaCompleto ? "(Día completo)" : "$inicio - $fin"}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        subtitle: motivo.isNotEmpty ? Text(motivo) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () async {
                            try {
                              await _svc.deleteBloqueo(b['id']);
                              await _cargarBloqueos();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
  }
}
