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

class _TurnosTabState extends State<TurnosTab> with SingleTickerProviderStateMixin {
  final _svc = SupabaseService.instance;
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _consultorios = [];
  // Turnos por consultorio_id
  Map<String, List<Map<String, dynamic>>> _turnosPorConsultorio = {};
  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _pacientes = [];
  bool _cargando = true;
  bool _mostrarCalendario = false;
  TabController? _consultorioTabController;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      _consultorios = await _svc.loadConsultorios();
      _zonas = await _svc.loadZonas();
      _promos = await _svc.loadPromos();
      _pacientes = await _svc.loadPacientes();

      if (_consultorios.isNotEmpty) {
        _consultorioTabController?.dispose();
        _consultorioTabController = TabController(
          length: _consultorios.length,
          vsync: this,
        );
      }

      await _cargarTurnos();
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _cargarTurnos() async {
    setState(() => _cargando = true);
    try {
      _turnosPorConsultorio = {};
      for (final c in _consultorios) {
        final turnos = await _svc.loadTurnosPorFechaConsultorio(_fechaSeleccionada, c['id']);
        _turnosPorConsultorio[c['id']] = turnos;
      }
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

      // Si se completa y tiene paciente con zonas, incrementar sesiones
      if (nuevoEstado == 'completado' && turno['paciente_id'] != null) {
        final zonasIds = turno['zonas_ids'];
        if (zonasIds != null && (zonasIds as List).isNotEmpty) {
          await _svc.incrementarSesionesZona(
            turno['paciente_id'],
            List<String>.from(zonasIds),
          );
        }
      }

      await _cargarTurnos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _mostrarDialogoNuevoTurno() async {
    if (_consultorios.isEmpty) return;

    final horaController = TextEditingController();
    final obsController = TextEditingController();
    final telBuscarController = TextEditingController();
    String? pacienteId;
    String nombrePaciente = '';
    String telefonoPaciente = '';
    List<String> zonasSeleccionadas = [];
    String? promoSeleccionada;
    String consultorioId = _consultorios[_consultorioTabController?.index ?? 0]['id'];
    String estado = 'pendiente';
    String metodoPago = 'efectivo';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Calcular tiempo total
          int tiempoTotal = 0;
          if (promoSeleccionada != null) {
            final promo = _promos.firstWhere((p) => p['id'] == promoSeleccionada, orElse: () => {});
            if (promo.isNotEmpty) tiempoTotal = promo['duracion_minutos'] ?? 0;
          }
          // Zonas sueltas (no en promo) suman tiempo
          for (final zId in zonasSeleccionadas) {
            final zona = _zonas.firstWhere((z) => z['id'] == zId, orElse: () => {});
            if (zona.isNotEmpty) {
              tiempoTotal += (zona['duracion_minutos'] as int?) ?? 5;
            }
          }

          // Calcular precio
          double precioEfectivo = 0;
          double precioTarjeta = 0;
          if (promoSeleccionada != null) {
            final promo = _promos.firstWhere((p) => p['id'] == promoSeleccionada, orElse: () => {});
            if (promo.isNotEmpty) {
              precioEfectivo = (promo['precio_efectivo'] as num?)?.toDouble() ?? 0;
              precioTarjeta = (promo['precio_tarjeta'] as num?)?.toDouble() ?? 0;
            }
          }
          for (final zId in zonasSeleccionadas) {
            final zona = _zonas.firstWhere((z) => z['id'] == zId, orElse: () => {});
            if (zona.isNotEmpty) {
              precioEfectivo += (zona['precio_efectivo'] as num?)?.toDouble() ?? 0;
              precioTarjeta += (zona['precio_tarjeta'] as num?)?.toDouble() ?? 0;
            }
          }

          // Descuento por cantidad de zonas
          final totalZonas = zonasSeleccionadas.length + (promoSeleccionada != null ? 1 : 0);
          double descuento = 0;
          if (totalZonas >= 5) {
            descuento = AppConfig.descuentosDefault[5] ?? 30;
          } else if (totalZonas >= 2) {
            descuento = AppConfig.descuentosDefault[totalZonas] ?? 0;
          }

          return AlertDialog(
            title: const Text('Nuevo Turno'),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consultorio
                    DropdownButtonFormField<String>(
                      value: consultorioId,
                      decoration: const InputDecoration(labelText: 'Consultorio'),
                      items: _consultorios.map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(c['nombre'] as String),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => consultorioId = v!),
                    ),
                    const SizedBox(height: 12),
                    // Hora
                    TextField(
                      controller: horaController,
                      decoration: const InputDecoration(
                        labelText: 'Hora (ej: 08:30)',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Buscar paciente por telefono
                    Text('Buscar paciente por teléfono:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: telBuscarController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Nº teléfono...',
                        prefixIcon: const Icon(Icons.phone),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            if (telBuscarController.text.isEmpty) return;
                            final resultados = await _svc.buscarPacientePorTelefono(telBuscarController.text);
                            if (resultados.isNotEmpty) {
                              final p = resultados.first;
                              setDialogState(() {
                                pacienteId = p['id'];
                                nombrePaciente = p['nombre'];
                                telefonoPaciente = p['telefono'] ?? '';
                              });
                            } else {
                              setDialogState(() {
                                pacienteId = null;
                                telefonoPaciente = telBuscarController.text;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (pacienteId != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConfig.colorExito.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: AppConfig.colorExito),
                            const SizedBox(width: 8),
                            Text('$nombrePaciente - $telefonoPaciente', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Nombre paciente (si es nuevo)
                    if (pacienteId == null)
                      TextField(
                        decoration: const InputDecoration(labelText: 'Nombre paciente (nuevo)'),
                        onChanged: (v) => nombrePaciente = v,
                      ),
                    const SizedBox(height: 12),
                    // Promo
                    if (_promos.isNotEmpty) ...[
                      Text('Promo:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String?>(
                        value: promoSeleccionada,
                        decoration: const InputDecoration(hintText: 'Sin promo'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Sin promo')),
                          ..._promos.map((p) => DropdownMenuItem<String?>(
                            value: p['id'] as String,
                            child: Text('${p['nombre']} (${p['duracion_minutos']}min)'),
                          )),
                        ],
                        onChanged: (v) => setDialogState(() => promoSeleccionada = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Zonas adicionales
                    Text('Zonas adicionales:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _zonas.map((z) {
                        final selected = zonasSeleccionadas.contains(z['id']);
                        return FilterChip(
                          label: Text('${z['nombre']} (${z['duracion_minutos']}min)'),
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
                    // Resumen tiempo y precio
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Duración:', style: GoogleFonts.inter(fontSize: 13)),
                              Text('$tiempoTotal min', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Efectivo:', style: GoogleFonts.inter(fontSize: 13)),
                              Text('\$${precioEfectivo.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.colorExito)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tarjeta:', style: GoogleFonts.inter(fontSize: 13)),
                              Text('\$${precioTarjeta.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.colorMercadoPago)),
                            ],
                          ),
                          if (descuento > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Descuento ($totalZonas zonas):', style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorAcento)),
                                Text('${descuento.toStringAsFixed(0)}% OFF', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.colorAcento)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Estado
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
                      decoration: const InputDecoration(labelText: 'Observaciones', alignLabelWithHint: true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  if (horaController.text.isEmpty && estado != 'no_dar_turno') return;

                  final nombresZonas = _zonas
                      .where((z) => zonasSeleccionadas.contains(z['id']))
                      .map((z) => z['nombre'] as String)
                      .join(', ');

                  String promoNombre = '';
                  if (promoSeleccionada != null) {
                    final promo = _promos.firstWhere((p) => p['id'] == promoSeleccionada, orElse: () => {});
                    if (promo.isNotEmpty) promoNombre = promo['nombre'] ?? '';
                  }

                  final precioFinal = metodoPago == 'efectivo'
                      ? precioEfectivo * (1 - descuento / 100)
                      : precioTarjeta * (1 - descuento / 100);

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
                    'consultorio_id': consultorioId,
                    'paciente_id': pacienteId,
                    'nombre_paciente': nombrePaciente,
                    'telefono_paciente': telefonoPaciente,
                    'zonas_ids': zonasSeleccionadas,
                    'zonas_nombres': promoNombre.isNotEmpty
                        ? (nombresZonas.isNotEmpty ? '$promoNombre + $nombresZonas' : promoNombre)
                        : nombresZonas,
                    'promo_id': promoSeleccionada,
                    'tiempo_sesion_minutos': tiempoTotal,
                    'precio': metodoPago == 'efectivo' ? precioEfectivo : precioTarjeta,
                    'descuento_porcentaje': descuento,
                    'precio_final': precioFinal,
                    'resta_pagar': precioFinal,
                    'estado': estado,
                    'observaciones': obsController.text,
                  };

                  try {
                    await _svc.createTurno(turnoData);
                    Navigator.pop(ctx);
                    await _cargarTurnos();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                      );
                    }
                  }
                },
                child: const Text('Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _consultorioTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _cargarTurnos();
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mostrarCalendario = !_mostrarCalendario),
                  child: Text(
                    formatFecha.format(_fechaSeleccionada),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  _fechaSeleccionada = _fechaSeleccionada.add(const Duration(days: 1));
                  _cargarTurnos();
                },
              ),
              IconButton(
                icon: const Icon(Icons.today),
                tooltip: 'Hoy',
                onPressed: () {
                  _fechaSeleccionada = DateTime.now();
                  _cargarTurnos();
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
                _cargarTurnos();
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
        // Solapas de consultorios
        if (_consultorioTabController != null && _consultorios.isNotEmpty)
          Container(
            color: AppConfig.colorPrimario.withValues(alpha: 0.05),
            child: TabBar(
              controller: _consultorioTabController,
              labelColor: AppConfig.colorPrimario,
              unselectedLabelColor: AppConfig.colorTextoClaro,
              indicatorColor: AppConfig.colorAcento,
              tabs: _consultorios.map((c) => Tab(
                text: c['nombre'] as String,
              )).toList(),
            ),
          ),
        // Lista de turnos por consultorio
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : _consultorioTabController != null
                  ? TabBarView(
                      controller: _consultorioTabController,
                      children: _consultorios.map((c) {
                        final turnos = _turnosPorConsultorio[c['id']] ?? [];
                        return _buildListaTurnos(turnos);
                      }).toList(),
                    )
                  : const Center(child: Text('Sin consultorios configurados')),
        ),
      ],
    );
  }

  Widget _buildListaTurnos(List<Map<String, dynamic>> turnos) {
    if (turnos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('Sin turnos para este día', style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: turnos.length,
      itemBuilder: (ctx, i) => _buildTurnoCard(turnos[i]),
    );
  }

  Widget _buildTurnoCard(Map<String, dynamic> turno) {
    final estado = turno['estado'] as String? ?? 'pendiente';
    final color = _colorEstado(estado);
    final hora = turno['hora'] as String? ?? '';
    final horaCorta = hora.length >= 5 ? hora.substring(0, 5) : hora;
    final nombre = turno['nombre_paciente'] as String? ?? '';
    final zonas = turno['zonas_nombres'] as String? ?? '';
    final tiempo = turno['tiempo_sesion_minutos'] ?? 0;
    final obs = turno['observaciones'] as String? ?? '';
    final esBloqueado = estado == 'no_dar_turno' || estado == 'practica';
    final esSuperAdmin = _svc.isSuperAdmin;

    // Color de fondo segun estado
    Color? bgColor;
    if (estado == 'completado') bgColor = AppConfig.colorExito.withValues(alpha: 0.06);
    if (estado == 'no_show') bgColor = AppConfig.colorPendiente.withValues(alpha: 0.06);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: bgColor,
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
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (tiempo > 0)
                    Text(
                      '${tiempo}min',
                      style: GoogleFonts.inter(fontSize: 11, color: AppConfig.colorTextoClaro),
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
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                    ),
                  ),
                ],
              ),
              if (!esBloqueado) ...[
                const SizedBox(height: 8),
                if (zonas.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.flash_on, size: 14, color: AppConfig.colorAcento),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(zonas, style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorTextoClaro)),
                      ),
                    ],
                  ),
                // Precios - solo super_admin
                if (esSuperAdmin) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chipPrecio('Total', turno['precio_final'], AppConfig.colorTexto),
                      const SizedBox(width: 8),
                      _chipPrecio('Seña', turno['sena'], Colors.blue),
                      const SizedBox(width: 8),
                      _chipPrecio('Efvo', turno['pago_efectivo'], AppConfig.colorExito),
                      const SizedBox(width: 8),
                      _chipPrecio('MP', turno['pago_mercado_pago'], AppConfig.colorMercadoPago),
                      const SizedBox(width: 8),
                      _chipPrecio('Tarj', turno['pago_tarjeta'], Colors.purple),
                      const SizedBox(width: 8),
                      _chipPrecio('Resta', turno['resta_pagar'], AppConfig.colorPendiente),
                    ],
                  ),
                ],
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(obs, style: GoogleFonts.inter(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (estado == 'pendiente' || estado == 'confirmado') ...[
                      _botonEstado('Check In', Icons.login, Colors.blue, () => _cambiarEstado(turno, 'en_atencion')),
                      const SizedBox(width: 8),
                      _botonEstado('No Show', Icons.person_off, AppConfig.colorPendiente, () => _cambiarEstado(turno, 'no_show')),
                    ],
                    if (estado == 'en_atencion')
                      _botonEstado('Completar', Icons.check_circle, AppConfig.colorExito, () => _cambiarEstado(turno, 'completado')),
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
        await _cargarTurnos();
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
