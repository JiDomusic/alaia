import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class TurnosTab extends StatefulWidget {
  const TurnosTab({super.key});

  @override
  State<TurnosTab> createState() => _TurnosTabState();
}

class _TurnosTabState extends State<TurnosTab> {
  final _svc = SupabaseService.instance;
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _turnos = [];
  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargando = true;
  bool _mostrarCalendario = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final turnos = await _svc.loadTurnosPorFecha(_fechaSeleccionada);
      final zonas = await _svc.loadZonas();
      final pacientes = await _svc.loadPacientes();
      if (mounted) {
        setState(() {
          _turnos = turnos;
          _zonas = zonas;
          _pacientes = pacientes;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'completado': return AppConfig.colorExito;
      case 'en_atencion': return AppConfig.colorEnAtencion;
      case 'cancelado': return Colors.grey;
      case 'no_show': return AppConfig.colorPendiente;
      case 'confirmado': return Colors.blue;
      case 'no_dar_turno': return Colors.red.shade900;
      case 'practica': return Colors.purple;
      default: return Colors.amber;
    }
  }

  String _labelEstado(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'confirmado': return 'Confirmado';
      case 'en_atencion': return 'En atención';
      case 'completado': return 'Completado';
      case 'cancelado': return 'Cancelado';
      case 'no_show': return 'No Show';
      case 'no_dar_turno': return 'NO DAR TURNO';
      case 'practica': return 'PRÁCTICA';
      default: return estado;
    }
  }

  Future<void> _cambiarEstado(Map<String, dynamic> turno, String nuevoEstado) async {
    try {
      await _svc.updateTurno(turno['id'], {'estado': nuevoEstado});
      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _mostrarDialogoNuevoTurno() async {
    final horaController = TextEditingController();
    final obsController = TextEditingController();
    String? pacienteId;
    String nombrePaciente = '';
    String telefonoPaciente = '';
    List<String> zonasSeleccionadas = [];
    int sesion = 1;
    String estado = 'pendiente';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo Turno'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hora
                  TextField(
                    controller: horaController,
                    decoration: const InputDecoration(
                      labelText: 'Hora (ej: 08:30)',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Paciente - busqueda
                  Autocomplete<Map<String, dynamic>>(
                    displayStringForOption: (p) => p['nombre'] ?? '',
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) return [];
                      return _pacientes.where((p) =>
                        (p['nombre'] as String).toLowerCase().contains(textEditingValue.text.toLowerCase())
                      );
                    },
                    onSelected: (p) {
                      setDialogState(() {
                        pacienteId = p['id'];
                        nombrePaciente = p['nombre'];
                        telefonoPaciente = p['telefono'] ?? '';
                      });
                    },
                    fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Paciente (buscar por nombre)',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (v) {
                          if (pacienteId != null) {
                            setDialogState(() {
                              pacienteId = null;
                              nombrePaciente = v;
                            });
                          } else {
                            nombrePaciente = v;
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Telefono
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    controller: TextEditingController(text: telefonoPaciente),
                    onChanged: (v) => telefonoPaciente = v,
                  ),
                  const SizedBox(height: 12),
                  // Zonas
                  Text('Zonas:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _zonas.map((z) {
                      final selected = zonasSeleccionadas.contains(z['id']);
                      return FilterChip(
                        label: Text(z['nombre']),
                        selected: selected,
                        onSelected: (v) {
                          setDialogState(() {
                            if (v) {
                              zonasSeleccionadas.add(z['id']);
                            } else {
                              zonasSeleccionadas.remove(z['id']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Sesion
                  Row(
                    children: [
                      Text('Sesión Nº: ', style: GoogleFonts.inter()),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(isDense: true),
                          controller: TextEditingController(text: '$sesion'),
                          onChanged: (v) => sesion = int.tryParse(v) ?? 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Estado especial
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'confirmado', child: Text('Confirmado')),
                      DropdownMenuItem(value: 'no_dar_turno', child: Text('NO DAR TURNO')),
                      DropdownMenuItem(value: 'practica', child: Text('PRÁCTICA')),
                    ],
                    onChanged: (v) => setDialogState(() => estado = v!),
                  ),
                  const SizedBox(height: 12),
                  // Observaciones
                  TextField(
                    controller: obsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (horaController.text.isEmpty && estado != 'no_dar_turno') return;

                // Calcular nombres de zonas
                final nombresZonas = _zonas
                    .where((z) => zonasSeleccionadas.contains(z['id']))
                    .map((z) => z['nombre'] as String)
                    .join(', ');

                // Calcular precio con descuento
                double precioTotal = 0;
                for (final zId in zonasSeleccionadas) {
                  final zona = _zonas.firstWhere((z) => z['id'] == zId, orElse: () => {});
                  if (zona.isNotEmpty) {
                    precioTotal += (zona['precio'] as num?)?.toDouble() ?? 0;
                  }
                }

                double descuento = 0;
                final cantZonas = zonasSeleccionadas.length;
                if (cantZonas >= 5) {
                  descuento = AppConfig.descuentosDefault[5] ?? 30;
                } else if (cantZonas >= 2) {
                  descuento = AppConfig.descuentosDefault[cantZonas] ?? 0;
                }

                final precioFinal = precioTotal * (1 - descuento / 100);
                final fechaStr = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);

                // Crear paciente si es nuevo
                if (pacienteId == null && nombrePaciente.isNotEmpty) {
                  try {
                    final nuevoPaciente = await _svc.createPaciente({
                      'nombre': nombrePaciente,
                      'telefono': telefonoPaciente,
                    });
                    pacienteId = nuevoPaciente['id'];
                  } catch (_) {}
                }

                final turnoData = {
                  'fecha': fechaStr,
                  'hora': horaController.text.isEmpty ? '00:00' : horaController.text,
                  'paciente_id': pacienteId,
                  'nombre_paciente': nombrePaciente,
                  'telefono_paciente': telefonoPaciente,
                  'zonas_ids': zonasSeleccionadas,
                  'zonas_nombres': nombresZonas,
                  'numero_sesion': sesion,
                  'precio': precioTotal,
                  'descuento_porcentaje': descuento,
                  'precio_final': precioFinal,
                  'resta_pagar': precioFinal,
                  'estado': estado,
                  'observaciones': obsController.text,
                };

                try {
                  await _svc.createTurno(turnoData);
                  Navigator.pop(ctx);
                  await _cargarDatos();
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
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 600;
    final formatFecha = DateFormat('EEEE d MMMM yyyy', 'es_AR');

    return Column(
      children: [
        // Barra de fecha
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 1));
                  _cargarDatos();
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mostrarCalendario = !_mostrarCalendario),
                  child: Text(
                    formatFecha.format(_fechaSeleccionada),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _fechaSeleccionada = _fechaSeleccionada.add(const Duration(days: 1));
                  _cargarDatos();
                },
              ),
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Hoy',
                onPressed: () {
                  _fechaSeleccionada = DateTime.now();
                  _cargarDatos();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoNuevoTurno,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.colorAcento,
                  foregroundColor: AppConfig.colorPrimario,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        // Calendario expandible
        if (_mostrarCalendario)
          Container(
            color: Colors.white,
            child: TableCalendar(
              locale: 'es_AR',
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              focusedDay: _fechaSeleccionada,
              selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
              onDaySelected: (selected, focused) {
                setState(() {
                  _fechaSeleccionada = selected;
                  _mostrarCalendario = false;
                });
                _cargarDatos();
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppConfig.colorPrimario,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppConfig.colorAcento.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        // Lista de turnos
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _turnos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Sin turnos para este día',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _turnos.length,
                      itemBuilder: (ctx, i) => _buildTurnoCard(_turnos[i], esMovil),
                    ),
        ),
      ],
    );
  }

  Widget _buildTurnoCard(Map<String, dynamic> turno, bool esMovil) {
    final estado = turno['estado'] as String? ?? 'pendiente';
    final color = _colorEstado(estado);
    final hora = turno['hora'] as String? ?? '';
    final horaCorta = hora.length >= 5 ? hora.substring(0, 5) : hora;
    final nombre = turno['nombre_paciente'] as String? ?? '';
    final zonas = turno['zonas_nombres'] as String? ?? '';
    final sesion = turno['numero_sesion'] ?? 1;
    final obs = turno['observaciones'] as String? ?? '';
    final esBloqueado = estado == 'no_dar_turno' || estado == 'practica';

    // Pago info - solo para super_admin
    final esSuperAdmin = _svc.isSuperAdmin;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: hora + nombre + estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.colorPrimario,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      horaCorta,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      esBloqueado ? _labelEstado(estado) : nombre,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: esBloqueado ? color : AppConfig.colorTexto,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _labelEstado(estado),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (!esBloqueado) ...[
                const SizedBox(height: 8),
                // Zonas + sesion
                if (zonas.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 14, color: AppConfig.colorAcento),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          zonas,
                          style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorTextoClaro),
                        ),
                      ),
                      Text(
                        'Sesión $sesion',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConfig.colorTextoClaro,
                        ),
                      ),
                    ],
                  ),
                // Precios - solo super_admin
                if (esSuperAdmin) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipPrecio('Precio', turno['precio_final'], AppConfig.colorTexto),
                      const SizedBox(width: 8),
                      _chipPrecio('Seña', turno['sena'], Colors.blue),
                      const SizedBox(width: 8),
                      _chipPrecio('Efvo', turno['pago_efectivo'], AppConfig.colorExito),
                      const SizedBox(width: 8),
                      _chipPrecio('MP', turno['pago_mercado_pago'], AppConfig.colorMercadoPago),
                    ],
                  ),
                ],
                // Observaciones
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      obs,
                      style: GoogleFonts.inter(fontSize: 12, color: AppConfig.colorTexto),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // Botones de accion
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (estado == 'pendiente' || estado == 'confirmado') ...[
                      _botonEstado('Check In', Icons.login, Colors.blue, () => _cambiarEstado(turno, 'en_atencion')),
                      const SizedBox(width: 8),
                      _botonEstado('No Show', Icons.person_off, AppConfig.colorPendiente, () => _cambiarEstado(turno, 'no_show')),
                    ],
                    if (estado == 'en_atencion') ...[
                      _botonEstado('Completar', Icons.check_circle, AppConfig.colorExito, () => _cambiarEstado(turno, 'completado')),
                    ],
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'editar', child: Text('Editar')),
                        const PopupMenuItem(value: 'obs', child: Text('Observaciones')),
                        if (_svc.isSuperAdmin)
                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                      ],
                      onSelected: (v) {
                        switch (v) {
                          case 'editar':
                            // TODO: dialogo editar turno
                            break;
                          case 'obs':
                            // TODO: dialogo observaciones paciente
                            break;
                          case 'eliminar':
                            _confirmarEliminar(turno);
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipPrecio(String label, dynamic valor, Color color) {
    final monto = (valor as num?)?.toDouble() ?? 0;
    if (monto == 0) return const SizedBox.shrink();
    return Text(
      '$label: \$${monto.toStringAsFixed(0)}',
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    );
  }

  Widget _botonEstado(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> turno) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar turno'),
        content: Text('¿Eliminar turno de ${turno['nombre_paciente']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await _svc.deleteTurno(turno['id']);
        await _cargarDatos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
          );
        }
      }
    }
  }
}
