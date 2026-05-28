import 'package:flutter/material.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/models/role.dart';
import '../../data/pharmacy_staff_api_service.dart';

class PharmacyOpsDashboard extends StatefulWidget {
  const PharmacyOpsDashboard({super.key});

  @override
  State<PharmacyOpsDashboard> createState() => _PharmacyOpsDashboardState();
}

class _PharmacyOpsDashboardState extends State<PharmacyOpsDashboard> {
  final _staffApi = PharmacyStaffApiService();
  String _pharmacyName = '';
  List<PharmacyOrderDto> _orders = [];
  bool _loading = true;

  bool get _isPharmacyAdmin => AppSession.activeRole == Role.pharmacyAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ctx = await _staffApi.getMyContext();
      final pharmacy = ctx['pharmacy'] as Map<String, dynamic>? ?? {};
      final orders = await _staffApi.listOrders();
      if (!mounted) return;
      setState(() {
        _pharmacyName = pharmacy['name'] as String? ?? 'Farmacia';
        _orders = orders;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pharmacyName),
        actions: [
          if (_isPharmacyAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.pharmacyAdminManage);
              },
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AppSession.clear();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _titleForRole(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_orders.isEmpty)
                  const Text('No hay pedidos registrados por la app.')
                else
                  ..._orders.map(_orderTile),
              ],
            ),
    );
  }

  String _titleForRole() {
    switch (AppSession.activeRole) {
      case Role.pharmacist:
        return 'Pedidos — revisión farmacéutica';
      case Role.pharmacyCashier:
        return 'Pedidos — caja';
      case Role.pharmacyAdmin:
        return 'Pedidos de la farmacia';
      default:
        return 'Pedidos';
    }
  }

  Widget _orderTile(PharmacyOrderDto order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(order.productName),
        subtitle: Text(
          'Cant: ${order.quantity} · \$${order.total.toStringAsFixed(2)} · ${order.status}',
        ),
        trailing: _actionsFor(order),
      ),
    );
  }

  Widget? _actionsFor(PharmacyOrderDto order) {
    if (AppSession.activeRole == Role.pharmacist && order.status == 'PENDING') {
      return TextButton(
        onPressed: () => _updateStatus(order.id, 'REVIEWING'),
        child: const Text('Revisar'),
      );
    }
    if (AppSession.activeRole == Role.pharmacyCashier &&
        (order.status == 'REVIEWING' || order.status == 'READY')) {
      return TextButton(
        onPressed: () => _updateStatus(order.id, 'COMPLETED'),
        child: const Text('Cobrar'),
      );
    }
    return null;
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _staffApi.updateOrderStatus(id, status);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
