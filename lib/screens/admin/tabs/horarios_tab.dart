import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class HorariosTab extends StatefulWidget {
  const HorariosTab({super.key});

  @override
  State<HorariosTab> createState() => _HorariosTabState();
}

class _HorariosTabState extends State<HorariosTab> {
  final _svc = SupabaseService.instance;
  List<Map<String, dynamic>> _horarios = [];
  bool _cargando = true;

  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _cargarHorarios();
  }

  Future<void> _cargarHorarios() async {
    setState(() => _cargando = true);
    try {
      _horarios = await _svc.loadHorarios();
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

  Future<void> _editarHorario(Map<String, dynamic> horario) async {
    final inicioCtrl = TextEditingController(text: horario['hora_inicio']?.toString().substring(0, 5) ?? '08:00');
    final finCtrl = TextEditingController(text: horario['hora_fin']?.toString().substring(0, 5) ?? '21:00');
    bool activo = horario['activo'] ?? true;
    final dia = horario['dia_semana'] as int;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(_dias[dia]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Abierto'),
                value: activo,
                onChanged: (v) => setDState(() => activo = v),
              ),
              if (activo) ...[
                const SizedBox(height: 12),
                TextField(controller: inicioCtrl, decoration: const InputDecoration(labelText: 'Hora inicio (ej: 08:00)')),
                const SizedBox(height: 12),
                TextField(controller: finCtrl, decoration: const InputDecoration(labelText: 'Hora fin (ej: 21:00)')),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _svc.updateHorario(horario['id'], {
                    'hora_inicio': inicioCtrl.text,
                    'hora_fin': finCtrl.text,
                    'activo': activo,
                  });
                  Navigator.pop(ctx);
                  await _cargarHorarios();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: const Text('Guardar'),
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
                Text('Horarios Operativos', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ..._horarios.map((h) {
                  final dia = h['dia_semana'] as int;
                  final activo = h['activo'] == true;
                  final inicio = h['hora_inicio']?.toString().substring(0, 5) ?? '';
                  final fin = h['hora_fin']?.toString().substring(0, 5) ?? '';

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        activo ? Icons.check_circle : Icons.cancel,
                        color: activo ? AppConfig.colorExito : Colors.grey,
                      ),
                      title: Text(
                        _dias[dia],
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: activo ? null : Colors.grey),
                      ),
                      subtitle: Text(
                        activo ? '$inicio - $fin' : 'Cerrado',
                        style: GoogleFonts.inter(fontSize: 13, color: activo ? AppConfig.colorTextoClaro : Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editarHorario(h),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
  }
}
