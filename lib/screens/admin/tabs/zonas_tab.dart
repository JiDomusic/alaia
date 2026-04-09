import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class ZonasTab extends StatefulWidget {
  const ZonasTab({super.key});

  @override
  State<ZonasTab> createState() => _ZonasTabState();
}

class _ZonasTabState extends State<ZonasTab> {
  final _svc = SupabaseService.instance;
  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _descuentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    setState(() => _cargando = true);
    try {
      final zonas = await _svc.loadZonas(soloActivas: false);
      final descuentos = await _svc.loadDescuentos();
      if (mounted) setState(() { _zonas = zonas; _descuentos = descuentos; _cargando = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
        );
      }
    }
  }

  Future<void> _mostrarDialogoZona({Map<String, dynamic>? zona}) async {
    final nombreCtrl = TextEditingController(text: zona?['nombre'] ?? '');
    final precioCtrl = TextEditingController(text: zona?['precio']?.toString() ?? '0');
    final duracionCtrl = TextEditingController(text: zona?['duracion_minutos']?.toString() ?? '20');
    final descCtrl = TextEditingController(text: zona?['descripcion'] ?? '');
    bool activa = zona?['activa'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(zona == null ? 'Nueva Zona' : 'Editar Zona'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Axilas, Bozo, Piernas)')),
                const SizedBox(height: 12),
                TextField(controller: precioCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (\$)')),
                const SizedBox(height: 12),
                TextField(controller: duracionCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duración (minutos)')),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activa'),
                  value: activa,
                  onChanged: (v) => setDState(() => activa = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) return;
                final data = {
                  'nombre': nombreCtrl.text.trim(),
                  'precio': double.tryParse(precioCtrl.text) ?? 0,
                  'duracion_minutos': int.tryParse(duracionCtrl.text) ?? 20,
                  'descripcion': descCtrl.text.trim(),
                  'activa': activa,
                };
                try {
                  if (zona == null) {
                    await _svc.createZona(data);
                  } else {
                    await _svc.updateZona(zona['id'], data);
                  }
                  Navigator.pop(ctx);
                  await _cargarZonas();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: Text(zona == null ? 'Crear' : 'Guardar'),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titulo + boton
                Row(
                  children: [
                    Text('Zonas de Tratamiento', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoZona(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva Zona'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Lista de zonas
                ..._zonas.map((z) => Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.flash_on,
                      color: z['activa'] == true ? AppConfig.colorAcento : Colors.grey,
                    ),
                    title: Text(
                      z['nombre'] ?? '',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: z['activa'] == true ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      '\$${((z['precio'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} - ${z['duracion_minutos'] ?? 20} min',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _mostrarDialogoZona(zona: z),
                    ),
                  ),
                )),
                const SizedBox(height: 32),
                // Descuentos
                Text('Descuentos por Zonas', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _descuentos.map((d) {
                        final cant = d['cantidad_zonas'] as int;
                        final porc = d['porcentaje_descuento'];
                        final label = cant >= 5 ? '5 o más zonas' : '$cant zonas';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(label, style: GoogleFonts.inter(fontSize: 14)),
                              Text(
                                '${porc.toStringAsFixed(0)}% OFF',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.colorAcento),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
