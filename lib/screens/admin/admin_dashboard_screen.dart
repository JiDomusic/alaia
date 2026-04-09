import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_config.dart';
import '../../services/supabase_service.dart';
import '../home_screen.dart';
import 'tabs/turnos_tab.dart';
import 'tabs/pacientes_tab.dart';
import 'tabs/caja_tab.dart';
import 'tabs/zonas_tab.dart';
import 'tabs/horarios_tab.dart';
import 'tabs/bloqueos_tab.dart';
import 'tabs/config_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _svc = SupabaseService.instance;

  List<_TabInfo> get _tabs {
    final tabs = <_TabInfo>[
      _TabInfo('Turnos', Icons.calendar_today, const TurnosTab()),
      _TabInfo('Pacientes', Icons.people, const PacientesTab()),
    ];

    // Solo super_admin ve caja, zonas, horarios, bloqueos, config
    if (_svc.isSuperAdmin) {
      tabs.addAll([
        _TabInfo('Caja', Icons.point_of_sale, const CajaTab()),
        _TabInfo('Zonas', Icons.flash_on, const ZonasTab()),
        _TabInfo('Horarios', Icons.schedule, const HorariosTab()),
        _TabInfo('Bloqueos', Icons.block, const BloqueosTab()),
        _TabInfo('Config', Icons.settings, const ConfigTab()),
      ]);
    }

    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Querés cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar')),
        ],
      ),
    );
    if (confirmar == true) {
      await _svc.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    final ancho = MediaQuery.of(context).size.width;
    final esMovil = ancho < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConfig.colorPrimario,
        foregroundColor: AppConfig.colorSecundario,
        title: Row(
          children: [
            Text(
              'Alaía',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConfig.colorSecundario,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _svc.isSuperAdmin
                    ? AppConfig.colorAcento.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _svc.isSuperAdmin ? 'ADMIN' : 'OPERADORA',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _svc.isSuperAdmin ? AppConfig.colorAcento : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppConfig.colorAcento,
          labelColor: AppConfig.colorSecundario,
          unselectedLabelColor: AppConfig.colorSecundario.withValues(alpha: 0.5),
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: tabs.map((t) => Tab(
            icon: esMovil ? Icon(t.icon, size: 20) : null,
            text: esMovil ? null : t.label,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((t) => t.widget).toList(),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  final Widget widget;
  _TabInfo(this.label, this.icon, this.widget);
}
