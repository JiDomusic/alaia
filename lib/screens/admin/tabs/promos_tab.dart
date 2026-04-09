import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_config.dart';
import '../../../services/supabase_service.dart';

class PromosTab extends StatefulWidget {
  const PromosTab({super.key});

  @override
  State<PromosTab> createState() => _PromosTabState();
}

class _PromosTabState extends State<PromosTab> {
  final _svc = SupabaseService.instance;
  List<Map<String, dynamic>> _promos = [];
  List<Map<String, dynamic>> _zonas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      _promos = await _svc.loadPromos(soloActivas: false);
      _zonas = await _svc.loadZonas();
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

  Future<void> _mostrarDialogoPromo({Map<String, dynamic>? promo}) async {
    final nombreCtrl = TextEditingController(text: promo?['nombre'] ?? '');
    final descCtrl = TextEditingController(text: promo?['descripcion'] ?? '');
    final duracionCtrl = TextEditingController(text: promo?['duracion_minutos']?.toString() ?? '15');
    final precioEfCtrl = TextEditingController(text: promo?['precio_efectivo']?.toString() ?? '0');
    final precioTjCtrl = TextEditingController(text: promo?['precio_tarjeta']?.toString() ?? '0');
    List<String> zonasSeleccionadas = List<String>.from(promo?['zonas_ids'] ?? []);
    bool activa = promo?['activa'] ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: Text(promo == null ? 'Nueva Promo' : 'Editar Promo'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (ej: Axila + Acabado)')),
                  const SizedBox(height: 12),
                  TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción'), maxLines: 2),
                  const SizedBox(height: 12),
                  TextField(controller: duracionCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duración total (minutos)')),
                  const SizedBox(height: 12),
                  TextField(controller: precioEfCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Efectivo (\$)')),
                  const SizedBox(height: 12),
                  TextField(controller: precioTjCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio Tarjeta (\$)')),
                  const SizedBox(height: 12),
                  Text('Zonas incluidas:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _zonas.map((z) {
                      final selected = zonasSeleccionadas.contains(z['id']);
                      return FilterChip(
                        label: Text(z['nombre'] ?? ''),
                        selected: selected,
                        onSelected: (v) {
                          setDState(() {
                            if (v) { zonasSeleccionadas.add(z['id']); }
                            else { zonasSeleccionadas.remove(z['id']); }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Activa'),
                    value: activa,
                    onChanged: (v) => setDState(() => activa = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.isEmpty) return;
                final nombresZonas = _zonas
                    .where((z) => zonasSeleccionadas.contains(z['id']))
                    .map((z) => z['nombre'] as String)
                    .join(', ');
                final data = {
                  'nombre': nombreCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim(),
                  'duracion_minutos': int.tryParse(duracionCtrl.text) ?? 15,
                  'precio_efectivo': double.tryParse(precioEfCtrl.text) ?? 0,
                  'precio_tarjeta': double.tryParse(precioTjCtrl.text) ?? 0,
                  'zonas_ids': zonasSeleccionadas,
                  'zonas_nombres': nombresZonas,
                  'activa': activa,
                };
                try {
                  if (promo == null) {
                    await _svc.createPromo(data);
                  } else {
                    await _svc.updatePromo(promo['id'], data);
                  }
                  Navigator.pop(ctx);
                  await _cargarDatos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppConfig.colorPendiente),
                  );
                }
              },
              child: Text(promo == null ? 'Crear' : 'Guardar'),
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
                    Text('Promos / Paquetes', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoPromo(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva Promo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cada promo agrupa zonas con un tiempo y precio fijo',
                  style: GoogleFonts.inter(fontSize: 13, color: AppConfig.colorTextoClaro),
                ),
                const SizedBox(height: 16),
                if (_promos.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Sin promos creadas')))
                else
                  ..._promos.map((p) => Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.local_offer,
                        color: p['activa'] == true ? AppConfig.colorAcento : Colors.grey,
                      ),
                      title: Text(
                        p['nombre'] ?? '',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: p['activa'] == true ? null : Colors.grey),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p['duracion_minutos']}min | Efvo: \$${((p['precio_efectivo'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} | Tarj: \$${((p['precio_tarjeta'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}'),
                          if ((p['zonas_nombres'] as String? ?? '').isNotEmpty)
                            Text('Zonas: ${p['zonas_nombres']}', style: GoogleFonts.inter(fontSize: 12, color: AppConfig.colorTextoClaro)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _mostrarDialogoPromo(promo: p),
                      ),
                      isThreeLine: true,
                    ),
                  )),
              ],
            ),
          );
  }
}
