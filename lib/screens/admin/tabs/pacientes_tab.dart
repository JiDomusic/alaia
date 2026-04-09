import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class PacientesTab extends StatefulWidget {
  const PacientesTab({super.key});

  @override
  State<PacientesTab> createState() => _PacientesTabState();
}

class _PacientesTabState extends State<PacientesTab> {
  final _svc = SupabaseService.instance;
  final _buscarController = TextEditingController();
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
  }

  Future<void> _cargarPacientes() async {
    setState(() => _cargando = true);
    try {
      final pacientes = _buscarController.text.isEmpty
          ? await _svc.loadPacientes()
          : await _svc.buscarPaciente(_buscarController.text);
      if (mounted) setState(() { _pacientes = pacientes; _cargando = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _mostrarDialogoPaciente({Map<String, dynamic>? paciente}) async {
    final nombreCtrl = TextEditingController(text: paciente?['nombre'] ?? '');
    final telCtrl = TextEditingController(text: paciente?['telefono'] ?? '');
    final emailCtrl = TextEditingController(text: paciente?['email'] ?? '');
    final cvuCtrl = TextEditingController(text: paciente?['cvu'] ?? '');
    final notasCtrl = TextEditingController(text: paciente?['notas'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(paciente == null ? 'Nuevo Paciente' : 'Editar Paciente'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo')),
                const SizedBox(height: 12),
                TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                TextField(controller: cvuCtrl, decoration: const InputDecoration(labelText: 'CVU')),
                const SizedBox(height: 12),
                TextField(controller: notasCtrl, decoration: const InputDecoration(labelText: 'Notas'), maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              final data = {
                'nombre': nombreCtrl.text.trim(),
                'telefono': telCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'cvu': cvuCtrl.text.trim(),
                'notas': notasCtrl.text.trim(),
              };
              try {
                if (paciente == null) {
                  await _svc.createPaciente(data);
                } else {
                  await _svc.updatePaciente(paciente['id'], data);
                }
                Navigator.pop(ctx);
                await _cargarPacientes();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                );
              }
            },
            child: Text(paciente == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarObservaciones(Map<String, dynamic> paciente) async {
    List<Map<String, dynamic>> observaciones = [];
    bool cargandoObs = true;
    final textoCtrl = TextEditingController();
    String tipoObs = 'general';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          if (cargandoObs) {
            _svc.loadObservaciones(paciente['id']).then((obs) {
              setDState(() { observaciones = obs; cargandoObs = false; });
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                Expanded(child: Text('${paciente['nombre']} - Observaciones')),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            content: SizedBox(
              width: 500,
              height: 500,
              child: Column(
                children: [
                  // Nueva observacion
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textoCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Nueva observación...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: tipoObs,
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'clinica', child: Text('Clínica')),
                          DropdownMenuItem(value: 'alerta', child: Text('Alerta')),
                        ],
                        onChanged: (v) => setDState(() => tipoObs = v!),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppConfig.colorAcento),
                        onPressed: () async {
                          if (textoCtrl.text.trim().isEmpty) return;
                          try {
                            await _svc.createObservacion({
                              'paciente_id': paciente['id'],
                              'texto': textoCtrl.text.trim(),
                              'tipo': tipoObs,
                            });
                            textoCtrl.clear();
                            setDState(() => cargandoObs = true);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lista
                  Expanded(
                    child: cargandoObs
                        ? const Center(child: CircularProgressIndicator())
                        : observaciones.isEmpty
                            ? const Center(child: Text('Sin observaciones'))
                            : ListView.builder(
                                itemCount: observaciones.length,
                                itemBuilder: (ctx, i) {
                                  final obs = observaciones[i];
                                  final tipo = obs['tipo'] ?? 'general';
                                  final fecha = DateTime.tryParse(obs['created_at'] ?? '');
                                  final autor = obs['usuarios']?['nombre'] ?? '';
                                  Color tipoColor;
                                  switch (tipo) {
                                    case 'alerta': tipoColor = AppConfig.colorPendiente; break;
                                    case 'clinica': tipoColor = Colors.blue; break;
                                    default: tipoColor = AppConfig.colorTextoClaro;
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: tipoColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border(left: BorderSide(color: tipoColor, width: 3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: tipoColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                tipo.toUpperCase(),
                                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: tipoColor),
                                              ),
                                            ),
                                            const Spacer(),
                                            if (fecha != null)
                                              Text(
                                                DateFormat('dd/MM/yy HH:mm').format(fecha),
                                                style: GoogleFonts.inter(fontSize: 11, color: AppConfig.colorTextoClaro),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(obs['texto'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                                        if (autor.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('— $autor', style: GoogleFonts.inter(fontSize: 11, color: AppConfig.colorTextoClaro, fontStyle: FontStyle.italic)),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Historial de turnos de un paciente
  Future<void> _mostrarHistorial(Map<String, dynamic> paciente) async {
    List<Map<String, dynamic>> turnos = [];
    bool cargando = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          if (cargando) {
            _svc.loadTurnosPaciente(paciente['id']).then((t) {
              setDState(() { turnos = t; cargando = false; });
            });
          }
          return AlertDialog(
            title: Text('${paciente['nombre']} - Historial'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : turnos.isEmpty
                      ? const Center(child: Text('Sin historial'))
                      : ListView.builder(
                          itemCount: turnos.length,
                          itemBuilder: (ctx, i) {
                            final t = turnos[i];
                            final fecha = t['fecha'] ?? '';
                            final hora = (t['hora'] as String?)?.substring(0, 5) ?? '';
                            final zonas = t['zonas_nombres'] ?? '';
                            final sesion = t['numero_sesion'] ?? 1;
                            final estado = t['estado'] ?? '';
                            return ListTile(
                              dense: true,
                              leading: Text('$fecha\n$hora', style: GoogleFonts.inter(fontSize: 12), textAlign: TextAlign.center),
                              title: Text(zonas, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text('Sesión $sesion', style: GoogleFonts.inter(fontSize: 12)),
                              trailing: Text(estado, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busqueda
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscarController,
                  decoration: InputDecoration(
                    hintText: 'Buscar paciente...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _buscarController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _buscarController.clear();
                              _cargarPacientes();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _cargarPacientes(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoPaciente(),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Nuevo'),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _pacientes.isEmpty
                  ? const Center(child: Text('Sin pacientes'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _pacientes.length,
                      itemBuilder: (ctx, i) {
                        final p = _pacientes[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppConfig.colorPrimario,
                              child: Text(
                                (p['nombre'] as String? ?? '?')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              p['nombre'] ?? '',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              p['telefono'] ?? '',
                              style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorTextoClaro),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.description, size: 20),
                                  tooltip: 'Observaciones',
                                  onPressed: () => _mostrarObservaciones(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.history, size: 20),
                                  tooltip: 'Historial',
                                  onPressed: () => _mostrarHistorial(p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Editar',
                                  onPressed: () => _mostrarDialogoPaciente(paciente: p),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }
}
