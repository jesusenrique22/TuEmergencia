// FullInventoryPage cleaned up
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class FullInventoryPage extends StatefulWidget {
  const FullInventoryPage({super.key});

  @override
  State<FullInventoryPage> createState() => _FullInventoryPageState();
}

class _FullInventoryPageState extends State<FullInventoryPage> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  final List<String> _categories = [
    'General',
    'Todos',
    'Stock Crítico',
    'Antibióticos',
    'Analgésicos',
    'Vitaminas',
    'Cuidado Personal',
    'Infantil',
  ];

  @override
  Widget build(BuildContext context) {
    final passedInventory =
        ModalRoute.of(context)?.settings.arguments
            as List<Map<String, dynamic>>?;
    final inventoryItems =
        passedInventory ??
        List.generate(20, (index) {
          final categories = [
            'Antibióticos',
            'Analgésicos',
            'Vitaminas',
            'Cuidado Personal',
            'Infantil',
          ];
          return {
            'name': 'Medicamento Demo ${index + 1}',
            'category': categories[index % categories.length],
            'stock': (index + 1) % 5 == 0 ? 3 : (index + 1) * 5,
            'price': 5.0 + (index * 2),
          };
        });

    final filteredItems = inventoryItems.where((item) {
      bool matchesCategory = false;
      if (_selectedCategory == 'Todos') {
        matchesCategory = true;
      } else if (_selectedCategory == 'Stock Crítico') {
        matchesCategory = (item['stock'] as int) < 5;
      } else {
        matchesCategory = item['category'] == _selectedCategory;
      }
      final matchesSearch = item['name'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();

    double totalValue = inventoryItems.fold(
      0,
      (sum, item) => sum + ((item['price'] as double) * (item['stock'] as int)),
    );
    int totalUnits = inventoryItems.fold(
      0,
      (sum, item) => sum + (item['stock'] as int),
    );

    return ResponsiveScaffold(
      title: const Text('Inventario Completo'),
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProductSheet(context, inventoryItems),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: const Text(
          'Agregar a Inventario',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      child: Column(
        children: [
          _buildFinancialSummary(totalValue, totalUnits),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o categoría...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          _buildCategoryFilter(),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isLowStock = item['stock'] < 15;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                            ),
                          ],
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: ListTile(
                          onTap: () => _showNewProductSheet(
                            context,
                            inventoryItems,
                            existingItem: item,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildProductThumbnail(item['image']),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Categoría: ${item['category']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${item['price'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['stock']} uds.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isLowStock
                                          ? Colors.red
                                          : Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isLowStock)
                                    const Text(
                                      'Stock Bajo',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Helper methods (unchanged from original file) are retained below.
  void _showNewProductSheet(
    BuildContext context,
    List<Map<String, dynamic>> inventory, {
    Map<String, dynamic>? existingItem,
  }) {
    final nameController = TextEditingController(text: existingItem?['name']);
    final stockController = TextEditingController(
      text: existingItem?['stock']?.toString(),
    );
    final priceController = TextEditingController(
      text: existingItem?['price']?.toString(),
    );
    final labController = TextEditingController(text: existingItem?['lab']);
    String selectedCategory = existingItem?['category'] ?? 'General';
    String? base64Image = existingItem?['image'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existingItem == null ? 'Nuevo Producto' : 'Editar Producto',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Imagen del Producto'),
                      GestureDetector(
                        onTap: () {
                          // Simulación de captura y conversión a Base64
                          setModalState(() {
                            base64Image = "IMAGE_DATA_BASE64_SIMULATED_EDITED";
                          });
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: base64Image == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Subir Fotografía (Base64)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _buildProductThumbnail(base64Image),
                                      Container(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      const Center(
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 12,
                                          child: Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Detalles Básicos'),
                      _buildTextField(
                        nameController,
                        'Nombre del Medicamento',
                        Icons.medication,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        labController,
                        'Laboratorio / Fabricante',
                        Icons.business_center,
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Clasificación'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            items: _categories
                                .where(
                                  (c) => c != 'Todos' && c != 'Stock Crítico',
                                )
                                .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                })
                                .toList(),
                            onChanged: (val) =>
                                setModalState(() => selectedCategory = val!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('Stock y Precio'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              stockController,
                              'Stock Actual',
                              Icons.inventory,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              priceController,
                              'Precio Unit. (\$)',
                              Icons.attach_money,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (existingItem != null) ...[
                TextButton.icon(
                  onPressed: () =>
                      _confirmDelete(context, inventory, existingItem),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'Eliminar Producto',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      stockController.text.isNotEmpty) {
                    setState(() {
                      if (existingItem != null) {
                        existingItem['name'] = nameController.text;
                        existingItem['category'] = selectedCategory;
                        existingItem['stock'] =
                            int.tryParse(stockController.text) ?? 0;
                        existingItem['price'] =
                            double.tryParse(priceController.text) ?? 0.0;
                        existingItem['lab'] = labController.text;
                        existingItem['image'] = base64Image;
                      } else {
                        inventory.add({
                          'name': nameController.text,
                          'category': selectedCategory,
                          'stock': int.tryParse(stockController.text) ?? 0,
                          'price': double.tryParse(priceController.text) ?? 0.0,
                          'lab': labController.text,
                          'image': base64Image,
                        });
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingItem == null
                              ? 'Producto guardado exitosamente'
                              : 'Producto actualizado correctamente',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  existingItem == null
                      ? 'Confirmar y Guardar'
                      : 'Actualizar Información',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(double totalValue, int totalUnits) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'Valor Total',
                '\$${totalValue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem(
                'Unidades',
                totalUnits.toString(),
                Icons.inventory_2,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildExportButton(
                'CSV',
                Icons.table_chart,
                () => _simulateExport('CSV'),
              ),
              const SizedBox(width: 16),
              _buildExportButton(
                'PDF',
                Icons.picture_as_pdf,
                () => _simulateExport('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.primary,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }

  void _simulateExport(String format) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Generando reporte $format...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Compilando datos del inventario y valoraciones contables',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Reporte $format descargado exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    List<Map<String, dynamic>> inventory,
    Map<String, dynamic> item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Producto?'),
        content: Text(
          'Esta acción eliminará "${item['name']}" permanentemente del inventario. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                inventory.remove(item);
              });
              Navigator.pop(context); // Close dialog
              Navigator.pop(this.context); // Close bottom sheet
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado del inventario'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(String? base64Data) {
    if (base64Data == null) {
      return const Icon(Icons.medication, color: AppColors.primary);
    }
    if (base64Data == "IMAGE_DATA_BASE64_SIMULATED") {
      return const Icon(Icons.image, color: AppColors.primary);
    }
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.red),
        ),
      );
    } catch (e) {
      return const Icon(Icons.error_outline, color: Colors.orange);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          final isCritical = category == 'Stock Crítico';
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isCritical ? Colors.red : AppColors.primary)
                    : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isCritical && isSelected
                      ? Colors.red
                      : AppColors.primaryLight,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isCritical ? Colors.red : AppColors.textPrimary),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
