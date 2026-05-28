import 'package:flutter/material.dart';
import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../domain/models/pharmacy_employee.dart';
import '../../domain/services/pharmacy_auth_service.dart';

class PharmacyAdminDashboard extends StatefulWidget {
  const PharmacyAdminDashboard({super.key});

  @override
  State<PharmacyAdminDashboard> createState() => _PharmacyAdminDashboardState();
}

class _PharmacyAdminDashboardState extends State<PharmacyAdminDashboard> {
  final PharmacyAuthService _auth = PharmacyAuthService();

  @override
  void initState() {
    super.initState();
    // Por defecto logueamos al primer Admin de la lista para la prueba inicial
    if (_auth.currentEmployee == null) {
      _auth.login('emp-001');
    }
  }

  void _switchRole(String empId) {
    setState(() {
      _auth.login(empId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final employee = _auth.currentEmployee;
    final pharmacy = _auth.currentPharmacy;

    if (employee == null || pharmacy == null) {
      return ResponsiveScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            SafeAvatar(radius: 18, imageUrl: pharmacy.logoUrl),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacy.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  employee.name,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildRoleSwitcher(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              AppSession.clear();
              _auth.logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(employee),
            const SizedBox(height: 24),

            // RBAC: Solo Admin ve Métricas Financieras
            if (_auth.isAdmin) ...[
              _buildSectionHeader('Métricas de Negocio'),
              const SizedBox(height: 16),
              _buildAdminMetrics(),
              const SizedBox(height: 32),
            ],

            // RBAC: Admin e Inventario ven Alertas de Stock
            if (_auth.isAdmin || _auth.isInventory) ...[
              _buildSectionHeader('Control de Inventario'),
              const SizedBox(height: 16),
              _buildInventoryAlerts(context),
              const SizedBox(height: 32),
            ],

            // RBAC: Admin y Cajero ven Pedidos
            if (_auth.isAdmin || _auth.isCashier) ...[
              _buildSectionHeader('Pedidos Pendientes'),
              const SizedBox(height: 16),
              _buildOrdersSection(),
            ],

            // RBAC: Solo Admin ve Gestión de Empleados
            if (_auth.isAdmin) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Gestión de Equipo'),
              const SizedBox(height: 16),
              _buildTeamManagement(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(PharmacyEmployee emp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel de Gestión',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Bienvenido, ${emp.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ROL: ${emp.role.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.analytics_outlined, color: Colors.white30, size: 60),
        ],
      ),
    );
  }

  Widget _buildAdminMetrics() {
    return Row(
      children: [
        _metricCard('Ventas Hoy', '\$1,240.50', Icons.payments, Colors.green),
        const SizedBox(width: 16),
        _metricCard('Margen', '24%', Icons.trending_up, Colors.blue),
      ],
    );
  }

  Widget _buildInventoryAlerts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                '3 Productos con Stock Bajo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.fullInventory);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gestionar Reposición'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: const Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Orden #ORD-882'),
            subtitle: Text('2 Items • Esperando Despacho'),
            trailing: Icon(Icons.arrow_forward_ios, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamManagement() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 150,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, color: Colors.grey),
              SizedBox(height: 4),
              Text(
                'Empleado X',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                'Cajero',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.supervised_user_circle, color: AppColors.primary),
      onSelected: _switchRole,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'emp-001',
          child: Text('Ver como Admin (FarmaVita)'),
        ),
        const PopupMenuItem(
          value: 'emp-002',
          child: Text('Ver como Inventario (FarmaVita)'),
        ),
        const PopupMenuItem(
          value: 'emp-003',
          child: Text('Ver como Cajero (EcoMedic)'),
        ),
      ],
    );
  }
}
