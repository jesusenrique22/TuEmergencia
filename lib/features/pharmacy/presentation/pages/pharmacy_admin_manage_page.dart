import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../admin/data/pharmacy_admin_api_service.dart';

class PharmacyAdminManagePage extends StatefulWidget {
  const PharmacyAdminManagePage({super.key});

  @override
  State<PharmacyAdminManagePage> createState() => _PharmacyAdminManagePageState();
}

class _PharmacyAdminManagePageState extends State<PharmacyAdminManagePage> {
  final _api = PharmacyAdminApiService();
  List<PharmacyProductDto> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await _api.listProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addProduct() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: stockCtrl,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.createProduct(
        name: nameCtrl.text,
        price: double.tryParse(priceCtrl.text) ?? 0,
        stock: int.tryParse(stockCtrl.text) ?? 0,
      );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addStaff(String role, String roleLabel) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Crear $roleLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Correo')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final result = await _api.createStaff(
        name: nameCtrl.text,
        email: emailCtrl.text,
        role: role,
        phone: phoneCtrl.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cuenta creada'),
          content: SelectableText(
            '${result.name}\nContraseña: ${result.temporaryPassword}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result.temporaryPassword));
                Navigator.pop(ctx);
              },
              child: const Text('Copiar'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de farmacia')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Personal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addStaff('PHARMACIST', 'farmacéutico'),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('Farmacéutico'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addStaff('PHARMACY_CASHIER', 'cajero'),
                        icon: const Icon(Icons.point_of_sale),
                        label: const Text('Cajero'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Inventario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._products.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.brand ?? ''} · Stock: ${p.stock} · \$${p.price.toStringAsFixed(2)}',
                      ),
                      trailing: Icon(
                        p.isAvailable ? Icons.check_circle : Icons.cancel,
                        color: p.isAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
