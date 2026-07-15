// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_design.dart';
import '../../../../core/widgets/experience/experience_header.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/promo/promo_carousel.dart';
import '../../../../core/widgets/promo/promo_models.dart';
import '../../domain/models/pharmacy_data_mock.dart';
import '../../domain/models/pharmacy.dart';
import '../../domain/models/prescription_search_result.dart';
import '../../domain/services/prescription_scanner_service.dart';
import 'pharmacy_detail_screen.dart';

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  final List<Pharmacy> _pharmacies = PharmacyDataMock.pharmacies;
  final PrescriptionScannerService _scannerService =
      PrescriptionScannerService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _globalSearchController = TextEditingController();
  PrescriptionSearchResult? _searchResult;
  bool _isProcessing = false;
  String _processingMessage = 'Buscando…';
  bool _searchFromImage = false;
  String? _searchStatusMessage;
  Color? _searchStatusColor;
  IconData? _searchStatusIcon;
  String _deliveryType = 'pickup';
  final double _deliveryFee = 3.50;
  PharmacyInventoryMatch? _selectedPharmacyMatch;
  bool _argumentsProcessed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsProcessed) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('prefilledMedications')) {
        _argumentsProcessed = true;
        final List<String> meds = List<String>.from(args['prefilledMedications'] ?? []);
        if (meds.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _runSearch(_scannerService.searchFromMedicationNames(meds));
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scannerService.dispose();
    _globalSearchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(
    Future<PrescriptionSearchResult> future, {
    bool fromImage = false,
  }) async {
    setState(() {
      _isProcessing = true;
      _searchFromImage = fromImage;
      _processingMessage = fromImage
          ? 'Leyendo tu receta…'
          : 'Buscando en farmacias…';
      _searchStatusMessage = null;
      _searchResult = null;
      _selectedPharmacyMatch = null;
    });
    try {
      final result = await future;
      _applySearchResult(result);
    } catch (e) {
      final message = _formatSearchError(e);
      setState(() {
        _isProcessing = false;
        _searchStatusMessage = message;
        _searchStatusColor = Colors.red.shade700;
        _searchStatusIcon = _errorIconForMessage(message);
      });
    }
  }

  IconData _errorIconForMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('no parece una receta') || lower.contains('not_prescription')) {
      return Icons.image_not_supported_outlined;
    }
    if (lower.contains('borrosa') || lower.contains('poca luz') || lower.contains('blurry')) {
      return Icons.blur_on_rounded;
    }
    if (lower.contains('no pudimos leer') || lower.contains('enfoca') || lower.contains('unreadable')) {
      return Icons.visibility_off_rounded;
    }
    if (lower.contains('no detectamos medicamentos') || lower.contains('no_medications')) {
      return Icons.medication_liquid_outlined;
    }
    if (lower.contains('503') || lower.contains('ocupado') || lower.contains('saturado')) {
      return Icons.hourglass_top_rounded;
    }
    return Icons.error_outline_rounded;
  }

  String _formatSearchError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '');
    if (raw.contains('no parece una receta') ||
        raw.contains('borrosa') ||
        raw.contains('No pudimos leer') ||
        raw.contains('no detectamos medicamentos') ||
        raw.contains('Parece una receta')) {
      return raw;
    }
    if (raw.contains('503') || raw.contains('high demand') || raw.contains('saturado')) {
      return 'El servicio está muy ocupado. Espera un minuto e intenta de nuevo, '
          'o escribe el medicamento en el buscador.';
    }
    if (raw.contains('404') || raw.contains('no longer available')) {
      return 'No pudimos procesar la receta en este momento. Intenta más tarde.';
    }
    if (raw.contains('GEMINI_API_KEY') || raw.contains('no configurada')) {
      return 'El escaneo de recetas no está disponible ahora. Busca el medicamento por nombre.';
    }
    if (raw.length > 120) {
      return 'No pudimos completar la búsqueda. Intenta de nuevo.';
    }
    return raw;
  }

  void _applySearchResult(PrescriptionSearchResult result) {
    final withStock = result.pharmacies.where((p) => p.items.isNotEmpty).toList();
    final fullCart = result.bestFullCart;

    String message;
    Color color;
    IconData icon;

    if (result.medications.isEmpty) {
      message = 'No se detectaron medicamentos. Sube una foto clara de tu receta médica.';
      color = Colors.red.shade700;
      icon = Icons.medication_liquid_outlined;
    } else if (withStock.isEmpty) {
      final names = result.medications.map((m) => m.detected).join(', ');
      message =
          'Detectamos: $names. No hay stock en farmacias aliadas por ahora.';
      color = Colors.orange.shade800;
      icon = Icons.inventory_2_outlined;
    } else if (fullCart != null) {
      message =
          '¡Encontrado! ${fullCart.pharmacy.name} tiene todos los medicamentos '
          '(\$${fullCart.total.toStringAsFixed(2)}).';
      color = Colors.green.shade700;
      icon = Icons.check_circle_rounded;
    } else {
      message =
          'Stock parcial en ${withStock.length} farmacia(s). Revisa opciones abajo.';
      color = Colors.orange.shade800;
      icon = Icons.info_outline_rounded;
    }

    setState(() {
      _searchResult = result;
      _isProcessing = false;
      _searchStatusMessage = message;
      _searchStatusColor = color;
      _searchStatusIcon = icon;
      _selectedPharmacyMatch =
          fullCart ?? (withStock.isNotEmpty ? withStock.first : null);
    });
  }

  void _selectPharmacyMatch(PharmacyInventoryMatch match) {
    setState(() => _selectedPharmacyMatch = match);
  }

  Pharmacy _pharmacyFromMatch(PharmacyMatchInfo info) {
    return Pharmacy(
      id: info.id,
      name: info.name,
      logoUrl: info.logoUrl ?? '',
      address: info.address,
      isActive: true,
    );
  }

  void _goToSelectedPharmacy() {
    final match = _selectedPharmacyMatch;
    if (match == null || match.items.isEmpty) {
      _showError('Elige una farmacia con stock disponible.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PharmacyDetailScreen(
          pharmacy: _pharmacyFromMatch(match.pharmacy),
          prefilledItems: match.items,
          initialDeliveryType: _deliveryType,
        ),
      ),
    );
  }

  Future<void> _pickPrescriptionImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      await _runSearch(_scannerService.searchFromXFile(image), fromImage: true);
    } catch (e) {
      final msg = e.toString();
      if (source == ImageSource.camera &&
          (msg.contains('Camera') || msg.contains('camera'))) {
        _showError(
          'La cámara no está disponible en simulador. Usa "Elegir foto de la galería".',
        );
        return;
      }
      _showError(msg.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _searchByText(String value) async {
    if (value.trim().isEmpty) return;
    await _runSearch(
      _scannerService.searchFromMedicationNames([value.trim()]),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideAppBar: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ExperienceHeader(
                  title: 'Farmacia',
                  subtitle: 'Busca medicinas, escanea recetas y compara precios.',
                  badge: '${_pharmacies.length} aliadas',
                  icon: Icons.local_pharmacy_rounded,
                  gradient: AppColors.pharmacyGradient,
                  actions: [
                    IconButton(
                      onPressed: () => AppNavigation.safeBack(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: PromoCarousel(
                    offers: PromoMockData.pharmacyPromos,
                    onOfferTap: (_) {},
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildSearchHeader()),
              if (_searchStatusMessage != null)
                SliverToBoxAdapter(child: _buildStatusBanner()),
              if (_searchResult != null)
                SliverToBoxAdapter(child: _buildSearchResults())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final pharmacy = _pharmacies[index];
                        return FadeSlideIn(
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildPharmacyCard(pharmacy),
                          ),
                        );
                      },
                      childCount: _pharmacies.length,
                    ),
                  ),
                ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _processingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchFromImage) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Luego buscaremos en el inventario de farmacias',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: 'scan_camera',
            onPressed: () => _pickPrescriptionImage(ImageSource.camera),
            backgroundColor: AppColors.secondary,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Cámara'),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'scan_gallery',
            onPressed: () => _pickPrescriptionImage(ImageSource.gallery),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Galería'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buscador inteligente',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _globalSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar medicina…',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onSubmitted: _searchByText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.explainPrescription),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Entender tu receta médica con IA ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _searchStatusColor!.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _searchStatusColor!.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_searchStatusIcon, color: _searchStatusColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _searchStatusMessage!,
                style: TextStyle(
                  color: _searchStatusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final result = _searchResult!;
    final selected = _selectedPharmacyMatch;
    final withStock =
        result.pharmacies.where((p) => p.items.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.medications.isNotEmpty) ...[
            const Text(
              'Medicamentos en tu receta',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.medications
                  .map(
                    (m) => Chip(
                      label: Text(m.detected),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionHeader('Elige tu farmacia'),
          const SizedBox(height: 6),
          const Text(
            'Toca la farmacia que prefieras y luego continúa para comprar.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...withStock.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPharmacyMatchCard(
                p,
                isSelected: p.pharmacy.id == selected?.pharmacy.id,
                onSelect: () => _selectPharmacyMatch(p),
              ),
            ),
          ),
          if (selected != null && selected.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildWinnerBanner(selected),
            const SizedBox(height: 16),
            _buildLogisticsSelector(),
            const SizedBox(height: 16),
            _buildCheckoutSummaryForMatch(selected),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _goToSelectedPharmacy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.storefront_rounded),
                label: Text('Comprar en ${selected.pharmacy.name}'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToSelectedPharmacy,
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: const Text('Ver carrito y confirmar pedido'),
              ),
            ),
          ],
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _searchResult = null;
                _selectedPharmacyMatch = null;
              }),
              child: const Text('Limpiar búsqueda'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(PharmacyInventoryMatch match) {
    final isFull = match.completeness == 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFull
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.orange.shade700, Colors.orange.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isFull ? Icons.stars_rounded : Icons.location_on_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFull
                      ? 'Farmacia seleccionada — receta completa'
                      : 'Farmacia seleccionada — stock parcial',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${match.completeness}% disponible · \$${match.total.toStringAsFixed(2)}'
                  '${match.pharmacy.distanceKm != null ? ' · ${match.pharmacy.distanceKm!.toStringAsFixed(1)} km' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyMatchCard(
    PharmacyInventoryMatch match, {
    bool isSelected = false,
    VoidCallback? onSelect,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? AppColors.secondary : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.pharmacy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    AppStatusPill(
                      label: '${match.completeness}%',
                      color: match.completeness == 100
                          ? AppColors.secondary
                          : Colors.orange,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ],
                ),
          if (match.pharmacy.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              match.pharmacy.address,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
          if (match.pharmacy.distanceKm != null) ...[
            const SizedBox(height: 4),
            Text(
              'A ${match.pharmacy.distanceKm!.toStringAsFixed(1)} km',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Divider(height: 20),
          ...match.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name)),
                  Text('\$${item.price.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          ...match.missing.map(
            (miss) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No disponible: $miss',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total estimado (IVA incl.)'),
              Text(
                '\$${match.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : null,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Seleccionada para comprar',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSummaryForMatch(PharmacyInventoryMatch match) {
    final finalTotal = _deliveryType == 'delivery'
        ? match.total + _deliveryFee
        : match.total;
    return _buildCheckoutSummary(
      subtotal: match.subtotal,
      tax: match.tax,
      finalTotal: finalTotal,
    );
  }

  Widget _buildLogisticsSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text(
            'Pick-up en Farmacia',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Retira tú mismo sin costo de envío',
            style: TextStyle(fontSize: 12),
          ),
          value: 'pickup',
          groupValue: _deliveryType,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _deliveryType = value!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
        ),
        const SizedBox(height: 12),
        RadioListTile<String>(
          title: const Text(
            'Delivery a Domicilio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Llega en 30-45 min (+\$${_deliveryFee.toStringAsFixed(2)})',
            style: const TextStyle(fontSize: 12),
          ),
          value: 'delivery',
          groupValue: _deliveryType,
          activeColor: AppColors.primary,
          onChanged: (value) => setState(() => _deliveryType = value!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildCheckoutSummary({
    required double subtotal,
    required double tax,
    required double finalTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('\$${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (12%)'),
              Text('\$${tax.toStringAsFixed(2)}'),
            ],
          ),
          if (_deliveryType == 'delivery') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Envío'),
                Text(
                  '\$${_deliveryFee.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Final',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '\$${finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildPharmacyCard(Pharmacy pharmacy, {bool isWinner = false}) {
    return AppMarketplaceTile(
      title: pharmacy.name,
      subtitle: pharmacy.address.isEmpty
          ? 'Farmacia aliada con inventario conectado.'
          : pharmacy.address,
      imageUrl: pharmacy.logoUrl,
      icon: Icons.local_pharmacy_rounded,
      color: isWinner ? AppColors.secondary : AppColors.primary,
      actionLabel: isWinner ? 'Seleccionada' : 'Comprar',
      chips: [
        AppStatusPill(
          label: pharmacy.isActive ? 'Disponible' : 'No disponible',
          color: pharmacy.isActive
              ? AppColors.secondary
              : AppColors.textTertiary,
          icon: pharmacy.isActive
              ? Icons.check_circle_rounded
              : Icons.pause_circle_rounded,
        ),
      ],
      onTap: isWinner
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
              ),
            ),
    );
  }
}
