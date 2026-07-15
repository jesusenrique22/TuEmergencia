import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/experience/fade_slide_in.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

// ── Modelo de categoría ──────────────────────────────────────────────────────
class _ServiceCategory {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String route;
  final String description;
  final String emoji;

  const _ServiceCategory({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.description,
    required this.emoji,
  });
}

const _allCategories = [
  _ServiceCategory(
    label: 'Agendar cita',
    icon: Icons.calendar_month_rounded,
    gradient: [Color(0xFF059669), Color(0xFF34D399)],
    route: AppRoutes.schedule,
    description: 'Presencial o videoconsulta',
    emoji: '📅',
  ),
  _ServiceCategory(
    label: 'Mis citas',
    icon: Icons.event_note_rounded,
    gradient: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    route: AppRoutes.appointments,
    description: 'Agenda y llamadas pendientes',
    emoji: '📋',
  ),
  _ServiceCategory(
    label: 'Laboratorios',
    icon: Icons.science_rounded,
    gradient: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
    route: AppRoutes.labMarketplace,
    description: 'Pruebas y paquetes con promo',
    emoji: '🔬',
  ),
  _ServiceCategory(
    label: 'Resultados',
    icon: Icons.assignment_turned_in_rounded,
    gradient: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    route: AppRoutes.labResults,
    description: 'Descarga y comparte estudios',
    emoji: '📊',
  ),
  _ServiceCategory(
    label: 'Farmacia',
    icon: Icons.local_pharmacy_rounded,
    gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    route: AppRoutes.pharmacy,
    description: 'Medicamentos y delivery rápido',
    emoji: '💊',
  ),
  _ServiceCategory(
    label: 'Explicar receta (IA)',
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF2563EB), Color(0xFF7C3AED)],
    route: AppRoutes.explainPrescription,
    description: 'Analiza dosis y efectos con IA',
    emoji: '✨',
  ),
  _ServiceCategory(
    label: 'Alquiler equipos',
    icon: Icons.personal_injury_rounded,
    gradient: [Color(0xFFF97316), Color(0xFFFBBF24)],
    route: AppRoutes.equipmentMarketplace,
    description: 'Sillas, oxígeno y más',
    emoji: '🩼',
  ),
  _ServiceCategory(
    label: 'Radiología',
    icon: Icons.image_search_rounded,
    gradient: [Color(0xFF6366F1), Color(0xFF818CF8)],
    route: AppRoutes.radiologyMarketplace,
    description: 'Rayos X, ecos y resonancias',
    emoji: '🩻',
  ),
  _ServiceCategory(
    label: 'Clínicas',
    icon: Icons.business_rounded,
    gradient: [Color(0xFF047857), Color(0xFF10B981)],
    route: AppRoutes.clinicNetwork,
    description: 'Red aliada y cobertura',
    emoji: '🏥',
  ),
  _ServiceCategory(
    label: 'Seguro médico',
    icon: Icons.shield_rounded,
    gradient: [Color(0xFFDC2626), Color(0xFFF97316)],
    route: AppRoutes.insuranceWallet,
    description: 'Pólizas y gestión de copagos',
    emoji: '🛡️',
  ),
  _ServiceCategory(
    label: 'Compartir exámenes',
    icon: Icons.upload_file_rounded,
    gradient: [Color(0xFF059669), Color(0xFF6EE7B7)],
    route: AppRoutes.patientShareExams,
    description: 'Envía estudios a tu médico',
    emoji: '📤',
  ),
  _ServiceCategory(
    label: 'Historial',
    icon: Icons.history_edu_rounded,
    gradient: [Color(0xFF475569), Color(0xFF94A3B8)],
    route: AppRoutes.medicalHistory,
    description: 'Visitas, recetas y antecedentes',
    emoji: '📁',
  ),
];

// ── Página principal ─────────────────────────────────────────────────────────
class HealthServicesHubPage extends StatefulWidget {
  const HealthServicesHubPage({super.key});

  @override
  State<HealthServicesHubPage> createState() => _HealthServicesHubPageState();
}

class _HealthServicesHubPageState extends State<HealthServicesHubPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > 60;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_ServiceCategory> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allCategories;
    return _allCategories
        .where(
          (c) =>
              c.label.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final w = MediaQuery.sizeOf(context).width;
    final crossAxisCount = w >= 900 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header con gradiente y búsqueda integrada
          SliverToBoxAdapter(child: _buildHeader(context)),

          // ── Barra de búsqueda flotante
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              query: _query,
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // ── Accesos rápidos destacados (solo cuando no hay búsqueda)
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: FadeSlideIn(
                index: 1,
                child: _buildFeaturedRow(context),
              ),
            ),

          // ── Grid de servicios
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmpty(),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _query.isEmpty
                      ? 'Todos los servicios'
                      : '${filtered.length} resultado${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                100,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 150,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FadeSlideIn(
                    index: index,
                    child: _ServiceGridCard(
                      category: filtered[index],
                      onTap: () =>
                          Navigator.pushNamed(context, filtered[index].route),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Círculos decorativos de fondo
            Positioned(
              top: -20,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.ambulanceCheckout),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emergency,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emergency.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emergency_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge y título
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_allCategories.length} servicios disponibles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tu salud,\nsin complicaciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Citas, labs, farmacia y más — todo en un lugar',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedRow(BuildContext context) {
    // Los 4 accesos rápidos más importantes
    const featured = [
      (
        label: 'Agendar',
        icon: Icons.calendar_month_rounded,
        color: Color(0xFF059669),
        route: AppRoutes.schedule,
      ),
      (
        label: 'Farmacia',
        icon: Icons.local_pharmacy_rounded,
        color: Color(0xFF8B5CF6),
        route: AppRoutes.pharmacy,
      ),
      (
        label: 'Laboratorio',
        icon: Icons.science_rounded,
        color: Color(0xFF0EA5E9),
        route: AppRoutes.labMarketplace,
      ),
      (
        label: 'Emergencia',
        icon: Icons.emergency_rounded,
        color: Color(0xFFEF4444),
        route: AppRoutes.ambulanceCheckout,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 12),
            child: Text(
              'Accesos rápidos',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Row(
            children: featured
                .map(
                  (f) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _QuickAccessButton(
                        label: f.label,
                        icon: f.icon,
                        color: f.color,
                        onTap: () => Navigator.pushNamed(context, f.route),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin resultados',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No encontramos servicios para "$_query"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de búsqueda persistente ────────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final String query;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBarDelegate({
    required this.query,
    required this.controller,
    required this.onChanged,
  });

  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = math.min(shrinkOffset / maxExtent, 1.0);
    return Material(
      elevation: t * 4,
      color: Color.lerp(const Color(0xFFF0FDF4), Colors.white, t),
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar servicio…',
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 15,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate old) =>
      old.query != query || old.controller != controller;
}

// ── Botón de acceso rápido ────────────────────────────────────────────────────
class _QuickAccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color == const Color(0xFFEF4444)
                  ? const Color(0xFFEF4444)
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de servicio (grid) ─────────────────────────────────────────────
class _ServiceGridCard extends StatefulWidget {
  final _ServiceCategory category;
  final VoidCallback onTap;

  const _ServiceGridCard({required this.category, required this.onTap});

  @override
  State<_ServiceGridCard> createState() => _ServiceGridCardState();
}

class _ServiceGridCardState extends State<_ServiceGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.category.gradient.first.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Franja de color superior
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.category.gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Blob decorativo en esquina
                Positioned(
                  top: -18,
                  right: -18,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.category.gradient.first
                          .withValues(alpha: 0.07),
                    ),
                  ),
                ),
                // Contenido
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícono con gradiente
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.category.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: widget.category.gradient.first
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.category.icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      // Nombre del servicio
                      Text(
                        widget.category.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Descripción breve
                      Text(
                        widget.category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de flecha
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.category.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wrapper con ResponsiveScaffold ───────────────────────────────────────────
class HealthServicesHub extends StatelessWidget {
  const HealthServicesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScaffold(
      hideAppBar: true,
      child: HealthServicesHubPage(),
    );
  }
}
