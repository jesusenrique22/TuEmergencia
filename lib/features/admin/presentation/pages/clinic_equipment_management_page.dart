import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/widgets/safe_avatar.dart';
import '../../../equipment_rental/data/equipment_api_service.dart';
import '../../../equipment_rental/domain/models/equipment_model.dart';

class ClinicEquipmentManagementPage extends StatefulWidget {
  const ClinicEquipmentManagementPage({super.key});

  @override
  State<ClinicEquipmentManagementPage> createState() => _ClinicEquipmentManagementPageState();
}

class _ClinicEquipmentManagementPageState extends State<ClinicEquipmentManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = EquipmentApiService();

  List<MedicalEquipment> _equipments = [];
  List<EquipmentRental> _rentals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getClinicEquipment(),
        _apiService.getClinicRentals(),
      ]);

      if (!mounted) return;

      setState(() {
        _equipments = results[0] as List<MedicalEquipment>;
        _rentals = results[1] as List<EquipmentRental>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ocurrió un error al cargar los datos';
        _loading = false;
      });
    }
  }

  void _showAddEditEquipmentDialog({MedicalEquipment? equipment}) {
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final descController = TextEditingController(text: equipment?.description ?? '');
    final priceController = TextEditingController(
      text: equipment != null ? equipment.pricePerDay.toStringAsFixed(2) : '',
    );
    final stockController = TextEditingController(
      text: equipment != null ? equipment.stock.toString() : '1',
    );
    final imageController = TextEditingController(text: equipment?.imageUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      equipment == null ? 'Agregar Equipo Médico' : 'Editar Equipo Médico',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Equipo',
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Silla de ruedas estándar',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Especificaciones',
                    border: OutlineInputBorder(),
                    hintText: 'Ej. Soporta hasta 120kg, plegable y liviana.',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Precio por Día (\$)',
                          border: OutlineInputBorder(),
                          prefixText: '\$ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad Stock',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL de Imagen (Opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://images.unsplash.com/...',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        priceController.text.trim().isEmpty ||
                        stockController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
                      );
                      return;
                    }

                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    final stock = int.tryParse(stockController.text.trim()) ?? 0;
                    final image = imageController.text.trim();

                    Navigator.pop(sheetCtx);

                    setState(() => _loading = true);

                    try {
                      if (equipment == null) {
                        await _apiService.addClinicEquipment(
                          name: name,
                          description: desc,
                          pricePerDay: price,
                          stock: stock,
                          imageUrl: image.isNotEmpty ? image : null,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Equipo agregado exitosamente'), backgroundColor: Colors.green),
                        );
                      } else {
                        await _apiService.updateClinicEquipment(
                          equipment.id,
                          name: name,
                          description: desc,
                          pricePerDay: price,
                          stock: stock,
                          imageUrl: image,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Equipo actualizado exitosamente'), backgroundColor: Colors.green),
                        );
                      }
                      _loadData();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                      setState(() => _loading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    equipment == null ? 'Guardar' : 'Actualizar',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleEquipmentState(MedicalEquipment eq, bool state) async {
    try {
      await _apiService.updateClinicEquipment(eq.id, isActive: state);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state ? 'Equipo activado' : 'Equipo inactivado'),
          duration: const Duration(seconds: 1),
        ),
      );
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cambiar estado'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteEquipment(MedicalEquipment eq) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: Text('¿Deseas dar de baja "${eq.name}" del catálogo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _apiService.deleteClinicEquipment(eq.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipo dado de baja exitosamente')),
      );
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar equipo'), backgroundColor: Colors.red),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _updateRentalStatus(EquipmentRental rental, String newStatus) async {
    setState(() => _loading = true);
    try {
      await _apiService.updateRentalStatus(rental.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud actualizada a: ${newStatus == 'ACTIVE' ? 'Entregado' : newStatus == 'COMPLETED' ? 'Devuelto' : 'Cancelado'}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar la solicitud'), backgroundColor: Colors.red),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos Médicos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventario'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Solicitudes'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInventoryTab(),
                    _buildRequestsTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_equipments.length} Equipos Registrados',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditEquipmentDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Nuevo Equipo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          if (_equipments.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No tienes equipos registrados.\nPresiona "Nuevo Equipo" para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final eq = _equipments[index];
                    return _buildEquipmentCard(eq);
                  },
                  childCount: _equipments.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(MedicalEquipment eq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: eq.isActive ? AppColors.primaryLight : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: SafeAvatar(
              radius: 30,
              imageUrl: eq.imageUrl,
              placeholderIcon: Icons.handyman_rounded,
            ),
            title: Text(
              eq.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  eq.description ?? 'Sin descripción',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${eq.pricePerDay.toStringAsFixed(2)} / día',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: eq.stock > 0 ? Colors.blue.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: ${eq.stock}',
                        style: TextStyle(
                          color: eq.stock > 0 ? Colors.blue.shade700 : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: eq.isActive,
                      activeColor: AppColors.primary,
                      onChanged: (val) => _toggleEquipmentState(eq, val),
                    ),
                    Text(
                      eq.isActive ? 'Activo' : 'Pausado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: eq.isActive ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                      tooltip: 'Editar',
                      onPressed: () => _showAddEditEquipmentDialog(equipment: eq),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: 'Baja del catálogo',
                      onPressed: () => _deleteEquipment(eq),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _rentals.isEmpty
          ? const Center(
              child: Text(
                'No has recibido solicitudes de alquiler aún.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rentals.length,
              itemBuilder: (context, index) {
                final rental = _rentals[index];
                return _buildRentalRequestCard(rental);
              },
            ),
    );
  }

  Widget _buildRentalRequestCard(EquipmentRental rental) {
    Color statusColor = Colors.orange;
    if (rental.status == 'ACTIVE') statusColor = Colors.blue;
    if (rental.status == 'COMPLETED') statusColor = Colors.green;
    if (rental.status == 'CANCELLED') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.equipment?.name ?? 'Equipo Médico',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paciente: ${rental.patientName ?? 'No disponible'}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rental.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.calendar_today_outlined, 'Período:',
                    '${rental.startDate.day}/${rental.startDate.month}/${rental.startDate.year} al ${rental.endDate.day}/${rental.endDate.month}/${rental.endDate.year}'),
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, 'Entrega:', rental.address),
                const SizedBox(height: 8),
                _infoRow(Icons.phone_outlined, 'Teléfono:', rental.phone),
                const SizedBox(height: 8),
                _infoRow(Icons.monetization_on_outlined, 'Costo Total:', '\$${rental.totalPrice.toStringAsFixed(2)}'),
              ],
            ),
          ),
          if (rental.status == 'PENDING' || rental.status == 'ACTIVE') ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (rental.status == 'PENDING') ...[
                    OutlinedButton(
                      onPressed: () => _updateRentalStatus(rental, 'CANCELLED'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Rechazar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _updateRentalStatus(rental, 'ACTIVE'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Aprobar y Entregar'),
                    ),
                  ],
                  if (rental.status == 'ACTIVE')
                    FilledButton.icon(
                      onPressed: () => _updateRentalStatus(rental, 'COMPLETED'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: const Text('Registrar Devolución', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
