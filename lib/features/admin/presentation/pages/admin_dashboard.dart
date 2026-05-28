import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/responsive_scaffold.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel Administrativo Global'),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('5'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Centro de notificaciones administrativas abierto',
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActions(context),
            const SizedBox(height: 32),
            const Text(
              'Métricas Globales de Operación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGlobalMetrics(),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reporte Semanal de Ingresos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Esta Semana',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWeeklyIncomeReport(context),
            const SizedBox(height: 32),
            const Text(
              'Tendencia Mensual de Ingresos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildIncomeComparisonChart(),
            const SizedBox(height: 32),
            _buildSystemIntelligence(context),
            const SizedBox(height: 32),
            const Text(
              'Análisis de Actividad Semanal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityChart(),
            const SizedBox(height: 32),
            const Text(
              'Distribución de Usuarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildUserSegmentation(),
            const SizedBox(height: 32),
            const Text(
              'Navegación de Módulos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildModuleNavigation(context),
            const SizedBox(height: 32),
            _buildActivityLog(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeComparisonChart() {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: IncomeBarPainter(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartLabel('Sem 1'),
              _chartLabel('Sem 2'),
              _chartLabel('Sem 3'),
              _chartLabel('Sem 4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWeeklyIncomeReport(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _incomeSubMetric('Total Bruto', '\$12,450', Colors.black),
              _incomeSubMetric('Telemedicina', '\$3,125', AppColors.primary),
              _incomeSubMetric('Presencial', '\$9,325', Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Crecimiento del 8.2% respecto a la semana anterior',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reporte financiero generado'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Descargar CSV',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _incomeSubMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickAction('Alertar Personal', Icons.campaign, Colors.red, context),
          const SizedBox(width: 12),
          _quickAction(
            'Reporte Diario',
            Icons.description,
            Colors.blue,
            context,
          ),
          const SizedBox(width: 12),
          _quickAction('Auditoría', Icons.security, Colors.orange, context),
          const SizedBox(width: 12),
          _quickAction('Configuración', Icons.settings, Colors.grey, context),
        ],
      ),
    );
  }

  Widget _quickAction(
    String label,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ejecutando: $label...'),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalMetrics() {
    return Row(
      children: [
        _metricCard('Ingresos Mes', '\$128.4k', '+12%', Colors.green),
        const SizedBox(width: 16),
        _metricCard('Emergencias', '1,240', '+5%', Colors.blue),
        const SizedBox(width: 16),
        _metricCard('Satisfacción', '98%', 'Stable', Colors.orange),
      ],
    );
  }

  Widget _metricCard(String label, String value, String trend, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                color: trend == 'Stable' ? Colors.grey : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(size: Size.infinite, painter: TrendPainter()),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartInfoItem('Dom', '40', Colors.grey),
              _chartInfoItem('Lun', '30', Colors.grey),
              _chartInfoItem('Mar', '60', Colors.grey),
              _chartInfoItem('Mie', '45', AppColors.primary),
              _chartInfoItem('Jue', '80', Colors.grey),
              _chartInfoItem('Vie', '50', Colors.grey),
              _chartInfoItem('Sab', '70', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartInfoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildSystemIntelligence(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'System Intelligence',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'El tráfico de emergencias ha aumentado un 15% en la última hora. Se recomienda alertar a la unidad de reserva VITA-09.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acción predictiva enviada a operaciones'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ejecutar Acción Predictiva'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSegmentation() {
    final segments = [
      {'role': 'Pacientes', 'count': '850', 'color': Colors.blue},
      {'role': 'Médicos', 'count': '120', 'color': Colors.green},
      {'role': 'Farmacéuticos', 'count': '45', 'color': Colors.orange},
      {'role': 'Conductores', 'count': '32', 'color': Colors.red},
    ];

    return Row(
      children: segments
          .map(
            (seg) => Expanded(
              child: Column(
                children: [
                  Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: (seg['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        seg['count'] as String,
                        style: TextStyle(
                          color: seg['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    seg['role'] as String,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildModuleNavigation(BuildContext context) {
    final modules = [
      {
        'name': 'Pacientes',
        'icon': Icons.person,
        'route': '/dashboard',
        'color': Colors.blue,
      },
      {
        'name': 'Médicos',
        'icon': Icons.health_and_safety,
        'route': '/doctor_dashboard',
        'color': Colors.green,
      },
      {
        'name': 'Emergencias',
        'icon': Icons.local_shipping,
        'route': '/ambulance_dashboard',
        'color': Colors.red,
      },
      {
        'name': 'Farmacia',
        'icon': Icons.local_pharmacy,
        'route': '/pharmacy_admin',
        'color': Colors.orange,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final mod = modules[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, mod['route'] as String),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (mod['color'] as Color).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mod['icon'] as IconData,
                  color: mod['color'] as Color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  mod['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityLog(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registro de Actividad Reciente',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Historial completo cargado')),
                );
              },
              child: const Text(
                'Ver historial',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _logItem(
          'VITA-01',
          'Ambulancia despachada a Zona Norte',
          'Hace 2m',
          Colors.blue,
        ),
        _logItem(
          'RX-203',
          'Receta controlada emitida por Dr. Aris',
          'Hace 15m',
          Colors.orange,
        ),
        _logItem(
          'SYS-UP',
          'Actualización de sistema completada',
          'Hace 1h',
          Colors.green,
        ),
      ],
    );
  }

  Widget _logItem(String code, String desc, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              code,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final data = [40.0, 30.0, 60.0, 45.0, 80.0, 50.0, 70.0];
    final xStep = size.width / (data.length - 1);

    path.moveTo(0, size.height - (data[0] / 100 * size.height));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (data[0] / 100 * size.height));

    for (int i = 1; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - (data[i] / 100 * size.height);

      // Smoothing curve
      final prevX = (i - 1) * xStep;
      final prevY = size.height - (data[i - 1] / 100 * size.height);

      path.cubicTo(prevX + xStep / 2, prevY, x - xStep / 2, y, x, y);
      fillPath.cubicTo(prevX + xStep / 2, prevY, x - xStep / 2, y, x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotStrokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - (data[i] / 100 * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 4, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class IncomeBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final data = [
      {'tele': 30.0, 'pres': 60.0}, // Sem 1
      {'tele': 40.0, 'pres': 50.0}, // Sem 2
      {'tele': 25.0, 'pres': 80.0}, // Sem 3
      {'tele': 45.0, 'pres': 70.0}, // Sem 4
    ];

    final barWidth = size.width / (data.length * 2.5);
    final spacing = size.width / data.length;

    for (int i = 0; i < data.length; i++) {
      final x = (i * spacing) + (spacing / 2) - barWidth;

      // Telemedicine Bar (Primary Color)
      paint.color = AppColors.primary.withValues(alpha: 0.8);
      final teleHeight = (data[i]['tele']! / 100) * size.height;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, size.height - teleHeight, barWidth, teleHeight),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );

      // In-person Bar (Green Color)
      paint.color = Colors.green.withValues(alpha: 0.8);
      final presHeight = (data[i]['pres']! / 100) * size.height;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            x + barWidth + 4,
            size.height - presHeight,
            barWidth,
            presHeight,
          ),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        paint,
      );
    }

    // Draw horizontal grid lines (subtle)
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
