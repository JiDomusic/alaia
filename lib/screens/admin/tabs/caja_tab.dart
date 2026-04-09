import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class CajaTab extends StatefulWidget {
  const CajaTab({super.key});

  @override
  State<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends State<CajaTab> {
  final _svc = SupabaseService.instance;
  DateTime _fecha = DateTime.now();
  Map<String, dynamic>? _caja;
  Map<String, dynamic> _resumen = {};
  List<Map<String, dynamic>> _movimientos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCaja();
  }

  Future<void> _cargarCaja() async {
    setState(() => _cargando = true);
    try {
      _caja = await _svc.loadCajaDiaria(_fecha);
      _resumen = await _svc.resumenCaja(_fecha);
      if (_caja != null) {
        _movimientos = await _svc.loadCajaMovimientos(_caja!['id']);
      } else {
        _movimientos = [];
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

  Future<void> _abrirCaja() async {
    final cambioCtrl = TextEditingController(text: '0');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: TextField(
          controller: cambioCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cambio inicial (\$)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(cambioCtrl.text) ?? 0),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        _caja = await _svc.getOrCreateCajaDiaria(_fecha);
        await _svc.updateCajaDiaria(_caja!['id'], {'cambio_inicio': result});
        await _cargarCaja();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
          );
        }
      }
    }
  }

  Future<void> _agregarMovimiento() async {
    if (_caja == null) {
      await _abrirCaja();
      if (_caja == null) return;
    }

    final descCtrl = TextEditingController();
    final montoCtrl = TextEditingController();
    String tipo = 'retiro';
    String responsable = 'DRA SECRE';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Nuevo Movimiento'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'retiro', child: Text('Retiro')),
                    DropdownMenuItem(value: 'gasto', child: Text('Gasto')),
                  ],
                  onChanged: (v) => setDState(() => tipo = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto (\$)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: responsable,
                  decoration: const InputDecoration(labelText: 'Responsable'),
                  items: const [
                    DropdownMenuItem(value: 'DRA SECRE', child: Text('DRA SECRE')),
                    DropdownMenuItem(value: 'DRA OP', child: Text('DRA OP')),
                    DropdownMenuItem(value: 'NK', child: Text('NK')),
                  ],
                  onChanged: (v) => setDState(() => responsable = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.isEmpty || montoCtrl.text.isEmpty) return;
                try {
                  await _svc.createCajaMovimiento({
                    'caja_id': _caja!['id'],
                    'tipo': tipo,
                    'descripcion': descCtrl.text.trim(),
                    'monto': double.tryParse(montoCtrl.text) ?? 0,
                    'responsable': responsable,
                  });
                  Navigator.pop(ctx);
                  await _cargarCaja();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cerrarCaja() async {
    if (_caja == null) return;
    final efRealCtrl = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cierre de Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _resumenRow('Total efectivo turnos', _resumen['total_efectivo']),
            _resumenRow('Total Mercado Pago', _resumen['total_mercado_pago']),
            _resumenRow('Total señas', _resumen['total_sena']),
            const Divider(),
            _resumenRow('Total retiros/gastos', _totalMovimientos()),
            const SizedBox(height: 16),
            TextField(
              controller: efRealCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Efectivo real en caja (\$)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(efRealCtrl.text) ?? 0),
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );

    if (result != null) {
      final totalEfTurnos = ((_resumen['total_efectivo'] as num?)?.toDouble() ?? 0);
      final cambioInicio = (_caja!['cambio_inicio'] as num?)?.toDouble() ?? 0;
      final totalRetiros = _totalMovimientos();
      final efectivoPlanilla = totalEfTurnos + cambioInicio - totalRetiros;
      final diferencia = result - efectivoPlanilla;

      try {
        await _svc.updateCajaDiaria(_caja!['id'], {
          'total_efectivo': _resumen['total_efectivo'] ?? 0,
          'total_mercado_pago': _resumen['total_mercado_pago'] ?? 0,
          'total_senas': _resumen['total_sena'] ?? 0,
          'total_senas_proxima': _resumen['total_sena_proxima'] ?? 0,
          'total_retiros': totalRetiros,
          'efectivo_real': result,
          'diferencia': diferencia,
          'cerrada': true,
          'cerrada_at': DateTime.now().toIso8601String(),
        });
        await _cargarCaja();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caja cerrada'), backgroundColor: AppConfig.colorExito),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
          );
        }
      }
    }
  }

  double _totalMovimientos() {
    double total = 0;
    for (final m in _movimientos) {
      total += (m['monto'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  Widget _resumenRow(String label, dynamic valor) {
    final monto = (valor as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13)),
          Text(
            '\$${monto.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatFecha = DateFormat('EEEE d MMMM', 'es_AR');
    final cajaCerrada = _caja?['cerrada'] == true;

    return Column(
      children: [
        // Barra fecha
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () { _fecha = _fecha.subtract(const Duration(days: 1)); _cargarCaja(); },
              ),
              Expanded(
                child: Text(
                  formatFecha.format(_fecha),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () { _fecha = _fecha.add(const Duration(days: 1)); _cargarCaja(); },
              ),
            ],
          ),
        ),
        // Contenido
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Estado caja
                      if (_caja == null)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _abrirCaja,
                            icon: const Icon(Icons.point_of_sale),
                            label: const Text('Abrir Caja'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.colorAcento,
                              foregroundColor: AppConfig.colorPrimario,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        )
                      else ...[
                        // Resumen
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Resumen del Día', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    if (cajaCerrada)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppConfig.colorExito.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('CERRADA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppConfig.colorExito)),
                                      ),
                                  ],
                                ),
                                const Divider(),
                                _resumenRow('Turnos', _resumen['cantidad_turnos']),
                                _resumenRow('Completados', _resumen['completados']),
                                _resumenRow('Cancelados', _resumen['cancelados']),
                                _resumenRow('No Show', _resumen['no_show']),
                                const Divider(),
                                _resumenRow('Total Precio', _resumen['total_precio']),
                                _resumenRow('Total Seña', _resumen['total_sena']),
                                _buildResumenColorRow('Efectivo', _resumen['total_efectivo'], AppConfig.colorExito),
                                _buildResumenColorRow('Mercado Pago', _resumen['total_mercado_pago'], AppConfig.colorMercadoPago),
                                _resumenRow('Resta pagar', _resumen['total_resta']),
                                _resumenRow('Seña próx. sesión', _resumen['total_sena_proxima']),
                                const Divider(),
                                _resumenRow('Cambio inicio', _caja!['cambio_inicio']),
                                _resumenRow('Total retiros/gastos', _totalMovimientos()),
                                if (cajaCerrada) ...[
                                  const Divider(),
                                  _buildResumenColorRow('Efectivo real', _caja!['efectivo_real'], AppConfig.colorPrimario),
                                  _buildResumenColorRow(
                                    'Diferencia',
                                    _caja!['diferencia'],
                                    ((_caja!['diferencia'] as num?)?.toDouble() ?? 0) >= 0
                                        ? AppConfig.colorExito
                                        : AppConfig.colorPendiente,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Movimientos
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Retiros / Gastos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    if (!cajaCerrada)
                                      TextButton.icon(
                                        onPressed: _agregarMovimiento,
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Agregar'),
                                      ),
                                  ],
                                ),
                                const Divider(),
                                if (_movimientos.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: Text('Sin movimientos')),
                                  )
                                else
                                  ..._movimientos.map((m) => ListTile(
                                    dense: true,
                                    leading: Icon(
                                      m['tipo'] == 'retiro' ? Icons.arrow_upward : Icons.shopping_cart,
                                      color: AppConfig.colorPendiente,
                                      size: 20,
                                    ),
                                    title: Text(m['descripcion'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                                    subtitle: Text(m['responsable'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppConfig.colorTextoClaro)),
                                    trailing: Text(
                                      '\$${((m['monto'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.colorPendiente),
                                    ),
                                  )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Boton cerrar
                        if (!cajaCerrada)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _cerrarCaja,
                              icon: const Icon(Icons.lock),
                              label: const Text('Cerrar Caja'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.colorPendiente,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResumenColorRow(String label, dynamic valor, Color color) {
    final monto = (valor as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13)),
          Text(
            '\$${monto.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
