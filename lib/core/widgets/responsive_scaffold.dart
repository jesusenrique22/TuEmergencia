import 'package:flutter/material.dart';
import '../branding/app_branding.dart';
import '../auth/app_session.dart';
import '../../features/auth/domain/models/role.dart';
import '../navigation/app_navigation.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';

/// A responsive scaffold that adapts its navigation UI based on screen width.
/// Supports optional AppBar, custom background color, and full‑screen
/// pages via `hideNavigation` (e.g., video call).
class ResponsiveScaffold extends StatefulWidget {
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBar;
  final bool hideNavigation;
  final bool hideAppBar;
  final Color? backgroundColor;
  final Widget? child;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const ResponsiveScaffold({
    super.key,
    this.title,
    this.actions,
    this.appBar,
    this.hideNavigation = false,
    this.hideAppBar = false,
    this.backgroundColor,
    this.child,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  void _navigateTo(String route) {
    final currentRoute = AppRoutes.normalize(
      ModalRoute.of(context)?.settings.name,
    );
    final targetRoute = AppRoutes.normalize(route);

    if (currentRoute == targetRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final String currentRoute = AppRoutes.normalize(
      ModalRoute.of(context)?.settings.name,
    );
    final bool canViewRoute =
        widget.hideNavigation ||
        AppRoutes.isAllowedForRole(currentRoute, AppSession.activeRole);
    final Widget pageContent = canViewRoute
        ? widget.body ?? widget.child ?? const SizedBox.shrink()
        : const _AccessDeniedView();

    // Optional AppBar.
    final List<Widget> resolvedActions = widget.actions != null ? List.from(widget.actions!) : [];
    if (AppSession.activeRole == Role.patient &&
        !widget.hideNavigation &&
        currentRoute != AppRoutes.ambulanceCheckout &&
        currentRoute != AppRoutes.videoCall &&
        currentRoute != AppRoutes.tracking) {
      resolvedActions.add(
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => _navigateTo(AppRoutes.ambulanceCheckout),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergency.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
        ),
      );
    }

    final PreferredSizeWidget? resolvedAppBar = widget.hideAppBar
        ? null
        : widget.appBar ??
            AppBar(
              title: widget.title ?? (widget.hideNavigation ? null : Text(AppRoutes.titleFor(currentRoute))),
              actions: resolvedActions.isEmpty ? null : resolvedActions,
            );

    // Full‑screen pages – hide navigation.
    if (widget.hideNavigation) {
      return Scaffold(
        appBar: resolvedAppBar,
        backgroundColor: widget.backgroundColor,
        body: pageContent,
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: widget.bottomNavigationBar,
      );
    }

    // Mobile layout.
    if (width < 600) {
      final destinations = AppRoutes.mobileDestinationsForRole(
        AppSession.activeRole,
      );
      final tabRoute = AppRoutes.tabRouteFor(currentRoute, AppSession.activeRole);
      final selectedIndex = destinations.indexWhere(
        (destination) => destination.path == tabRoute,
      );
      final emergencyFab = _resolveEmergencyFab(currentRoute);

      return Scaffold(
        appBar: resolvedAppBar,
        backgroundColor: widget.backgroundColor,
        body: pageContent,
        floatingActionButton: emergencyFab,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar:
            widget.bottomNavigationBar ??
            (destinations.length < 2
                ? null
                : NavigationBar(
                    selectedIndex: selectedIndex == -1 ? 0 : selectedIndex,
                    onDestinationSelected: (index) {
                      _navigateTo(destinations[index].path);
                    },
                    destinations: destinations
                        .map(
                          (destination) => NavigationDestination(
                            icon: Icon(destination.icon),
                            label: destination.label,
                          ),
                        )
                        .toList(),
                  )),
      );
    }

    final destinations = AppRoutes.destinationsForRole(AppSession.activeRole);
    final tabRoute = AppRoutes.tabRouteFor(currentRoute, AppSession.activeRole);
    final selectedIndex = destinations.indexWhere(
      (destination) =>
          destination.path == currentRoute || destination.path == tabRoute,
    );
    final isExtended = width >= 1200;
    final emergencyFab = _resolveEmergencyFab(currentRoute);
    final rail = Material(
      color: AppColors.primaryDark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF064E3B), Color(0xFF047857)],
          ),
        ),
        child: SizedBox(
        width: isExtended ? 260 : 92,
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: destinations.length + 2,
            separatorBuilder: (_, index) => index == 0
                ? const SizedBox(height: 18)
                : const SizedBox(height: 6),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SidebarBrand(isExtended: isExtended);
              }

              if (index == destinations.length + 1) {
                return _SidebarLogout(isExtended: isExtended);
              }

              final destination = destinations[index - 1];
              final isSelected = index - 1 == selectedIndex;

              if (!isExtended) {
                return Tooltip(
                  message: destination.label,
                  child: IconButton(
                    isSelected: isSelected,
                    style: IconButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.white.withValues(alpha: 0.16)
                          : Colors.transparent,
                      foregroundColor: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.62),
                      fixedSize: const Size(56, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _navigateTo(destination.path),
                    icon: Icon(destination.icon),
                  ),
                );
              }

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.white.withValues(alpha: 0.14),
                  selectedColor: Colors.white,
                  iconColor: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.62),
                  textColor: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  leading: Icon(destination.icon),
                  title: Text(
                    destination.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  onTap: () => _navigateTo(destination.path),
                ),
              );
            },
          ),
        ),
      ),
      ),
    );

    return Scaffold(
      appBar: resolvedAppBar,
      backgroundColor: widget.backgroundColor,
      floatingActionButton: emergencyFab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Row(
        children: [
          rail,
          Expanded(child: pageContent),
        ],
      ),
    );
  }

  Widget? _resolveEmergencyFab(String currentRoute) {
    return widget.floatingActionButton;
  }
}

class _SidebarBrand extends StatelessWidget {
  final bool isExtended;

  const _SidebarBrand({required this.isExtended});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabels = isExtended && constraints.maxWidth >= 120;

        return Row(
          mainAxisAlignment:
              showLabels ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                AppBranding.appIcon,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            if (showLabels) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppBranding.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  final bool isExtended;

  const _SidebarLogout({required this.isExtended});

  @override
  Widget build(BuildContext context) {
    if (!isExtended) {
      return Tooltip(
        message: 'Cerrar sesión',
        child: IconButton(
          style: IconButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.72),
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        iconColor: Colors.white.withValues(alpha: 0.72),
        textColor: Colors.white.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: const Icon(Icons.logout_rounded),
        title: const Text('Cerrar sesión'),
        onTap: () => _logout(context),
      ),
    );
  }

  void _logout(BuildContext context) {
    AppSession.clear();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
}

class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    final homeRoute = AppRoutes.normalize(
      AppNavigation.homeRouteForRole(AppSession.activeRole),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.emergencyLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.emergency,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Vista no disponible para este rol',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta sección no está habilitada para tu perfil actual.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, homeRoute),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ir al inicio'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  AppSession.clear();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Cambiar de cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
