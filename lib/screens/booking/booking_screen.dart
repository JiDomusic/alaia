import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/supabase_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  const BookingScreen({super.key, required this.config});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _paso = 0; // 0=promo/zonas, 1=consultorio, 2=fecha/hora, 3=datos, 4=confirmar
  bool _cargando = true;

  // Datos cargados
  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _consultorios = [];
  List<Map<String, dynamic>> _horarios = [];
  List<Map<String, dynamic>> _descuentos = [];
  Map<String, dynamic> _config = {};
  int _intervaloMinutos = 5;

  // Selecciones del usuario
  Map<String, dynamic>? _promoSeleccionada;
  List<Map<String, dynamic>> _zonasSeleccionadas = [];
  Map<String, dynamic>? _consultorioSeleccionado;
  DateTime? _fechaSeleccionada;
  String? _horaSeleccionada;

  // Datos paciente
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  // Colores dinámicos
  Color get _colorPrimario => AppConfig.hexToColor(widget.config['color_primario'] ?? '#1A1A1A');
  Color get _colorSecundario => AppConfig.hexToColor(widget.config['color_secundario'] ?? '#E8D5C4');
  Color get _colorAcento => AppConfig.hexToColor(widget.config['color_acento'] ?? '#D4AF37');
  Color get _colorFondo => AppConfig.hexToColor(widget.config['color_fondo'] ?? '#F5F0EB');
  Color get _colorTexto => AppConfig.hexToColor(widget.config['color_texto'] ?? '#2C2C2C');

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final futures = await Future.wait([
        SupabaseService.instance.loadPromos(),
        SupabaseService.instance.loadZonas(),
        SupabaseService.instance.loadConsultorios(),
        SupabaseService.instance.loadHorarios(),
        SupabaseService.instance.loadDescuentos(),
      ]);
      if (mounted) {
        setState(() {
          _promos = futures[0];
          _zonas = futures[1];
          _consultorios = futures[2];
          _horarios = futures[3];
          _descuentos = futures[4];
          _intervaloMinutos = (_config['intervalo_minutos'] as int?) ?? 5;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Duración total en minutos
  int get _duracionTotal {
    if (_promoSeleccionada != null) {
      return (_promoSeleccionada!['duracion_minutos'] as int?) ?? 15;
    }
    int total = 0;
    for (final z in _zonasSeleccionadas) {
      total += (z['duracion_minutos'] as int?) ?? 20;
    }
    return total > 0 ? total : 20;
  }

  // Precio según selección
  double get _precioEfectivo {
    if (_promoSeleccionada != null) {
      return ((_promoSeleccionada!['precio_efectivo'] as num?) ?? 0).toDouble();
    }
    double total = 0;
    for (final z in _zonasSeleccionadas) {
      total += ((z['precio_efectivo'] as num?) ?? 0).toDouble();
    }
    // Aplicar descuento por cantidad de zonas
    final cant = _zonasSeleccionadas.length;
    final desc = _getDescuento(cant);
    if (desc > 0) total = total * (1 - desc / 100);
    return total;
  }

  double get _precioTarjeta {
    if (_promoSeleccionada != null) {
      return ((_promoSeleccionada!['precio_tarjeta'] as num?) ?? 0).toDouble();
    }
    double total = 0;
    for (final z in _zonasSeleccionadas) {
      total += ((z['precio_tarjeta'] as num?) ?? 0).toDouble();
    }
    final cant = _zonasSeleccionadas.length;
    final desc = _getDescuento(cant);
    if (desc > 0) total = total * (1 - desc / 100);
    return total;
  }

  double _getDescuento(int cantZonas) {
    if (cantZonas < 2) return 0;
    // Buscar descuento exacto o el de 5+ para cantidades mayores
    for (final d in _descuentos) {
      final cant = d['cantidad_zonas'] as int;
      if (cant == cantZonas || (cant == 5 && cantZonas >= 5)) {
        return ((d['porcentaje_descuento'] as num?) ?? 0).toDouble();
      }
    }
    return 0;
  }

  String get _zonasNombresTexto {
    if (_promoSeleccionada != null) {
      return _promoSeleccionada!['zonas_nombres'] ?? _promoSeleccionada!['nombre'] ?? '';
    }
    return _zonasSeleccionadas.map((z) => z['nombre']).join(', ');
  }

  List<String> get _zonasIdsSeleccionadas {
    if (_promoSeleccionada != null) {
      final ids = _promoSeleccionada!['zonas_ids'];
      if (ids is List) return ids.map((e) => e.toString()).toList();
      return [];
    }
    return _zonasSeleccionadas.map((z) => z['id'].toString()).toList();
  }

  bool get _puedeAvanzar {
    switch (_paso) {
      case 0:
        return _promoSeleccionada != null || _zonasSeleccionadas.isNotEmpty;
      case 1:
        return _consultorioSeleccionado != null;
      case 2:
        return _fechaSeleccionada != null && _horaSeleccionada != null;
      case 3:
        return _nombreCtrl.text.trim().isNotEmpty && _telefonoCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _avanzar() {
    if (!_puedeAvanzar) return;
    setState(() => _paso++);
  }

  void _retroceder() {
    if (_paso == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _paso--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: _colorFondo,
        body: Center(child: CircularProgressIndicator(color: _colorAcento)),
      );
    }

    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 600;

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        backgroundColor: _colorPrimario,
        foregroundColor: _colorSecundario,
        title: Text('Reservar Turno', style: GoogleFonts.playfairDisplay()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _retroceder,
        ),
      ),
      body: Column(
        children: [
          // Stepper indicator
          _buildStepIndicator(),
          // Contenido del paso
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: esMovil ? 16 : 80,
                vertical: 24,
              ),
              child: _buildPasoActual(esMovil),
            ),
          ),
          // Botones
          _buildBottomBar(esMovil),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final pasos = ['Servicio', 'Consultorio', 'Horario', 'Datos', 'Confirmar'];
    return Container(
      color: _colorPrimario,
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Row(
        children: List.generate(pasos.length, (i) {
          final activo = i == _paso;
          final completado = i < _paso;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: completado
                        ? _colorAcento
                        : activo
                            ? _colorAcento.withValues(alpha: 0.6)
                            : _colorSecundario.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pasos[i],
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    color: activo || completado
                        ? _colorSecundario
                        : _colorSecundario.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPasoActual(bool esMovil) {
    switch (_paso) {
      case 0:
        return _buildPasoServicio(esMovil);
      case 1:
        return _buildPasoConsultorio(esMovil);
      case 2:
        return _buildPasoHorario(esMovil);
      case 3:
        return _buildPasoDatos(esMovil);
      case 4:
        return _buildPasoConfirmar(esMovil);
      default:
        return const SizedBox();
    }
  }

  // ============================================
  // PASO 0: Seleccionar promo o zonas individuales
  // ============================================
  Widget _buildPasoServicio(bool esMovil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué tratamiento querés?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Elegí una promo o seleccioná zonas individuales',
          style: GoogleFonts.inter(fontSize: 14, color: _colorTexto.withValues(alpha: 0.6)),
        ),
        // Promos
        if (_promos.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'PROMOS',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _colorAcento,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ..._promos.map((p) => _buildPromoCard(p)),
        ],
        // Zonas individuales
        if (_zonas.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'ZONAS INDIVIDUALES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _colorAcento,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _zonas.map((z) => _buildZonaChip(z)).toList(),
          ),
          if (_zonasSeleccionadas.length >= 2) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _colorAcento.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: _colorAcento, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_getDescuento(_zonasSeleccionadas.length).toStringAsFixed(0)}% OFF por ${_zonasSeleccionadas.length} zonas',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _colorAcento,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        // Resumen selección
        if (_promoSeleccionada != null || _zonasSeleccionadas.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildResumenSeleccion(),
        ],
      ],
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final seleccionada = _promoSeleccionada?['id'] == promo['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          if (seleccionada) {
            _promoSeleccionada = null;
          } else {
            _promoSeleccionada = promo;
            _zonasSeleccionadas = [];
          }
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? _colorPrimario : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionada ? _colorAcento : Colors.grey.shade200,
            width: seleccionada ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.flash_on,
              color: seleccionada ? _colorAcento : _colorAcento.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo['nombre'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: seleccionada ? _colorSecundario : _colorTexto,
                    ),
                  ),
                  if (promo['zonas_nombres'] != null && (promo['zonas_nombres'] as String).isNotEmpty)
                    Text(
                      promo['zonas_nombres'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: seleccionada
                            ? _colorSecundario.withValues(alpha: 0.7)
                            : _colorTexto.withValues(alpha: 0.5),
                      ),
                    ),
                  Text(
                    '${promo['duracion_minutos']} min',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: seleccionada
                          ? _colorSecundario.withValues(alpha: 0.7)
                          : _colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if ((_config['mostrar_precios_publico'] ?? false) == true) ...[
                  Text(
                    '\$${((promo['precio_efectivo'] as num?) ?? 0).toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: seleccionada ? _colorAcento : _colorTexto,
                    ),
                  ),
                  Text(
                    'efectivo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: seleccionada
                          ? _colorSecundario.withValues(alpha: 0.6)
                          : _colorTexto.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              seleccionada ? Icons.check_circle : Icons.radio_button_unchecked,
              color: seleccionada ? _colorAcento : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonaChip(Map<String, dynamic> zona) {
    final seleccionada = _zonasSeleccionadas.any((z) => z['id'] == zona['id']);
    return FilterChip(
      selected: seleccionada,
      onSelected: (sel) {
        setState(() {
          _promoSeleccionada = null; // Desmarcar promo si elige zonas
          if (sel) {
            _zonasSeleccionadas.add(zona);
          } else {
            _zonasSeleccionadas.removeWhere((z) => z['id'] == zona['id']);
          }
        });
      },
      label: Text(zona['nombre'] ?? ''),
      selectedColor: _colorAcento.withValues(alpha: 0.2),
      checkmarkColor: _colorAcento,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w400,
        color: seleccionada ? _colorPrimario : _colorTexto,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: seleccionada ? _colorAcento : Colors.grey.shade300,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildResumenSeleccion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorAcento.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duración', style: GoogleFonts.inter(fontSize: 13, color: _colorTexto.withValues(alpha: 0.6))),
              Text('$_duracionTotal min', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _colorTexto)),
            ],
          ),
          if ((_config['mostrar_precios_publico'] ?? false) == true) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Efectivo', style: GoogleFonts.inter(fontSize: 13, color: _colorTexto.withValues(alpha: 0.6))),
                Text('\$${_precioEfectivo.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _colorTexto)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tarjeta', style: GoogleFonts.inter(fontSize: 13, color: _colorTexto.withValues(alpha: 0.6))),
                Text('\$${_precioTarjeta.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, color: _colorTexto.withValues(alpha: 0.7))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // PASO 1: Seleccionar consultorio
  // ============================================
  Widget _buildPasoConsultorio(bool esMovil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegí un consultorio',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 24),
        ..._consultorios.map((c) {
          final seleccionado = _consultorioSeleccionado?['id'] == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _consultorioSeleccionado = c),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: seleccionado ? _colorPrimario : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: seleccionado ? _colorAcento : Colors.grey.shade200,
                  width: seleccionado ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    color: seleccionado ? _colorAcento : _colorTexto.withValues(alpha: 0.4),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    c['nombre'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: seleccionado ? _colorSecundario : _colorTexto,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: seleccionado ? _colorAcento : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================
  // PASO 2: Fecha y hora
  // ============================================
  Widget _buildPasoHorario(bool esMovil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elegí día y hora',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 24),
        // Calendario
        _buildCalendario(),
        if (_fechaSeleccionada != null) ...[
          const SizedBox(height: 24),
          Text(
            'Horarios disponibles',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _colorTexto,
            ),
          ),
          const SizedBox(height: 12),
          _buildSlots(),
        ],
      ],
    );
  }

  Widget _buildCalendario() {
    final ahora = DateTime.now();
    final maxDias = (_config['max_dias_adelanto'] as int?) ?? 30;
    final minHoras = (_config['min_anticipacion_horas'] as int?) ?? 2;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: CalendarDatePicker(
        initialDate: _fechaSeleccionada ?? ahora.add(Duration(hours: minHoras)),
        firstDate: ahora,
        lastDate: ahora.add(Duration(days: maxDias)),
        onDateChanged: (fecha) {
          // Verificar que el día tenga horario activo
          final diaSemana = fecha.weekday - 1; // 0=lunes
          final horarioDia = _horarios.where((h) =>
              h['dia_semana'] == diaSemana && h['activo'] == true).toList();
          if (horarioDia.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ese día no hay atención'),
                backgroundColor: AppConfig.colorPendiente,
              ),
            );
            return;
          }
          setState(() {
            _fechaSeleccionada = fecha;
            _horaSeleccionada = null; // Reset hora al cambiar fecha
          });
        },
      ),
    );
  }

  Widget _buildSlots() {
    if (_fechaSeleccionada == null) return const SizedBox();

    final diaSemana = _fechaSeleccionada!.weekday - 1;
    final horarioDia = _horarios.where((h) =>
        h['dia_semana'] == diaSemana && h['activo'] == true).toList();

    if (horarioDia.isEmpty) {
      return Text('No hay atención este día',
          style: GoogleFonts.inter(color: _colorTexto.withValues(alpha: 0.5)));
    }

    final horaInicio = _parseTime(horarioDia.first['hora_inicio'].toString());
    final horaFin = _parseTime(horarioDia.first['hora_fin'].toString());

    // Generar slots
    final slots = <String>[];
    var actual = horaInicio;
    while (actual.hour < horaFin.hour ||
        (actual.hour == horaFin.hour && actual.minute < horaFin.minute)) {
      // El turno tiene que caber en el horario (slot + duracion <= horaFin)
      final finTurno = actual.add(Duration(minutes: _duracionTotal));
      final finTurnoTime = TimeOfDay(hour: finTurno.hour, minute: finTurno.minute);
      final horaFinTime = TimeOfDay(hour: horaFin.hour, minute: horaFin.minute);
      if (finTurnoTime.hour > horaFinTime.hour ||
          (finTurnoTime.hour == horaFinTime.hour && finTurnoTime.minute > horaFinTime.minute)) {
        break;
      }
      final horaStr = '${actual.hour.toString().padLeft(2, '0')}:${actual.minute.toString().padLeft(2, '0')}';
      slots.add(horaStr);
      actual = actual.add(Duration(minutes: _intervaloMinutos));
    }

    // Filtrar slots pasados si es hoy
    final ahora = DateTime.now();
    final minHoras = (_config['min_anticipacion_horas'] as int?) ?? 2;
    final minTime = ahora.add(Duration(hours: minHoras));
    final esHoy = _fechaSeleccionada!.year == ahora.year &&
        _fechaSeleccionada!.month == ahora.month &&
        _fechaSeleccionada!.day == ahora.day;

    return FutureBuilder<List<String>>(
      future: _getSlotsOcupados(),
      builder: (context, snapshot) {
        final ocupados = snapshot.data ?? [];

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final ocupado = ocupados.contains(slot);
            final seleccionado = _horaSeleccionada == slot;

            // Verificar si ya pasó (si es hoy)
            bool pasado = false;
            if (esHoy) {
              final parts = slot.split(':');
              final slotTime = DateTime(
                _fechaSeleccionada!.year,
                _fechaSeleccionada!.month,
                _fechaSeleccionada!.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
              if (slotTime.isBefore(minTime)) pasado = true;
            }

            final deshabilitado = ocupado || pasado;

            return GestureDetector(
              onTap: deshabilitado ? null : () => setState(() => _horaSeleccionada = slot),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? _colorPrimario
                      : deshabilitado
                          ? Colors.grey.shade100
                          : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: seleccionado
                        ? _colorAcento
                        : deshabilitado
                            ? Colors.grey.shade200
                            : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  slot,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                    color: seleccionado
                        ? _colorAcento
                        : deshabilitado
                            ? Colors.grey.shade400
                            : _colorTexto,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<String>> _getSlotsOcupados() async {
    if (_fechaSeleccionada == null || _consultorioSeleccionado == null) return [];
    try {
      final turnos = await SupabaseService.instance.loadTurnosPorFechaConsultorio(
        _fechaSeleccionada!,
        _consultorioSeleccionado!['id'],
      );

      // Bloqueos
      final bloqueos = await SupabaseService.instance.loadBloqueos(
        desde: _fechaSeleccionada,
        hasta: _fechaSeleccionada,
      );

      final ocupados = <String>{};

      for (final turno in turnos) {
        if (turno['estado'] == 'cancelado') continue;
        final hora = turno['hora'].toString();
        final duracion = (turno['tiempo_sesion_minutos'] as int?) ?? 20;
        // Marcar todos los slots que ocupa este turno
        final parts = hora.split(':');
        var t = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
        for (int i = 0; i < duracion; i += _intervaloMinutos) {
          ocupados.add('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          t = t.add(Duration(minutes: _intervaloMinutos));
        }
      }

      for (final bloqueo in bloqueos) {
        // Filtrar por consultorio si el bloqueo tiene uno
        if (bloqueo['consultorio_id'] != null &&
            bloqueo['consultorio_id'] != _consultorioSeleccionado!['id']) {
          continue;
        }
        if (bloqueo['dia_completo'] == true) {
          // Todo el día bloqueado - devolver todos los slots
          return ['ALL_BLOCKED'];
        }
        if (bloqueo['hora_inicio'] != null && bloqueo['hora_fin'] != null) {
          final inicio = _parseTime(bloqueo['hora_inicio'].toString());
          final fin = _parseTime(bloqueo['hora_fin'].toString());
          var t = inicio;
          while (t.isBefore(fin)) {
            ocupados.add('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
            t = t.add(Duration(minutes: _intervaloMinutos));
          }
        }
      }

      return ocupados.toList();
    } catch (e) {
      return [];
    }
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  // ============================================
  // PASO 3: Datos del paciente
  // ============================================
  Widget _buildPasoDatos(bool esMovil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tus datos',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para confirmar tu turno necesitamos estos datos',
          style: GoogleFonts.inter(fontSize: 14, color: _colorTexto.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nombreCtrl,
          decoration: InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _telefonoCtrl,
          decoration: InputDecoration(
            labelText: 'Teléfono (WhatsApp)',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            hintText: 'Ej: 3411234567',
          ),
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ============================================
  // PASO 4: Confirmar
  // ============================================
  Widget _buildPasoConfirmar(bool esMovil) {
    final diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmá tu turno',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _colorTexto,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _colorAcento.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Servicio
              _buildConfirmRow(Icons.flash_on, 'Servicio', _promoSeleccionada?['nombre'] ?? _zonasNombresTexto),
              const Divider(height: 24),
              // Consultorio
              _buildConfirmRow(Icons.meeting_room_outlined, 'Consultorio', _consultorioSeleccionado?['nombre'] ?? ''),
              const Divider(height: 24),
              // Fecha
              if (_fechaSeleccionada != null)
                _buildConfirmRow(
                  Icons.calendar_today,
                  'Fecha',
                  '${diasSemana[_fechaSeleccionada!.weekday - 1]} ${_fechaSeleccionada!.day} ${meses[_fechaSeleccionada!.month]}',
                ),
              const Divider(height: 24),
              // Hora
              _buildConfirmRow(Icons.access_time, 'Hora', _horaSeleccionada ?? ''),
              const Divider(height: 24),
              // Duración
              _buildConfirmRow(Icons.timer_outlined, 'Duración', '$_duracionTotal min'),
              const Divider(height: 24),
              // Nombre
              _buildConfirmRow(Icons.person_outline, 'Nombre', _nombreCtrl.text),
              const Divider(height: 24),
              // Teléfono
              _buildConfirmRow(Icons.phone_outlined, 'Teléfono', _telefonoCtrl.text),
              if ((_config['mostrar_precios_publico'] ?? false) == true) ...[
                const Divider(height: 24),
                _buildConfirmRow(Icons.payments_outlined, 'Efectivo', '\$${_precioEfectivo.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _buildConfirmRow(Icons.credit_card, 'Tarjeta', '\$${_precioTarjeta.toStringAsFixed(0)}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _colorAcento),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: _colorTexto.withValues(alpha: 0.6)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _colorTexto),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ============================================
  // BOTTOM BAR
  // ============================================
  Widget _buildBottomBar(bool esMovil) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esMovil ? 16 : 80,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (_paso > 0)
            TextButton(
              onPressed: _retroceder,
              child: Text('Atrás', style: GoogleFonts.inter(color: _colorTexto.withValues(alpha: 0.6))),
            ),
          const Spacer(),
          if (_paso < 4)
            ElevatedButton(
              onPressed: _puedeAvanzar ? _avanzar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrimario,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Siguiente', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          if (_paso == 4)
            ElevatedButton.icon(
              onPressed: _confirmarReserva,
              icon: const Icon(Icons.check),
              label: Text('Confirmar Turno', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorAcento,
                foregroundColor: _colorPrimario,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // CONFIRMAR RESERVA
  // ============================================
  Future<void> _confirmarReserva() async {
    setState(() => _cargando = true);

    try {
      final fechaStr = '${_fechaSeleccionada!.year}-${_fechaSeleccionada!.month.toString().padLeft(2, '0')}-${_fechaSeleccionada!.day.toString().padLeft(2, '0')}';

      final turno = {
        'nombre_paciente': _nombreCtrl.text.trim(),
        'telefono_paciente': _telefonoCtrl.text.trim(),
        'fecha': fechaStr,
        'hora': _horaSeleccionada,
        'consultorio_id': _consultorioSeleccionado!['id'],
        'zonas_ids': _zonasIdsSeleccionadas,
        'zonas_nombres': _zonasNombresTexto,
        'tiempo_sesion_minutos': _duracionTotal,
        'precio': _precioEfectivo,
        'precio_final': _precioEfectivo,
        'estado': 'pendiente',
        'pago_estado': 'pendiente',
        'observaciones': _promoSeleccionada != null ? 'Promo: ${_promoSeleccionada!['nombre']}' : '',
      };

      if (_promoSeleccionada != null) {
        turno['promo_id'] = _promoSeleccionada!['id'];
      }

      if (_zonasSeleccionadas.length >= 2) {
        turno['descuento_porcentaje'] = _getDescuento(_zonasSeleccionadas.length);
      }

      await SupabaseService.instance.createTurno(turno);

      if (mounted) {
        setState(() => _cargando = false);
        _mostrarExito();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reservar: $e'),
            backgroundColor: AppConfig.colorPendiente,
          ),
        );
      }
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppConfig.colorExito, size: 64),
            const SizedBox(height: 16),
            Text(
              '¡Turno reservado!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _colorTexto,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu turno fue registrado. Te contactaremos por WhatsApp para confirmar.',
              style: GoogleFonts.inter(fontSize: 14, color: _colorTexto.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Volver al home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _colorPrimario,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Volver al inicio', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
