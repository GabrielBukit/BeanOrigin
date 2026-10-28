import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';

class ExportPort {
  final String name;
  final LatLng position;
  final String description;

  const ExportPort({
    required this.name,
    required this.position,
    required this.description,
  });
}

class MapScreen extends StatefulWidget {
  final double? focusLat;
  final double? focusLon;
  const MapScreen({super.key, this.focusLat, this.focusLon});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  late List<BatchModel> _batches;
  BatchModel? _selectedBatch;
  bool _showRoutes = true;

  // Major Indonesian coffee export ports
  static const List<ExportPort> _exportPorts = [
    ExportPort(
      name: 'Pelabuhan Belawan',
      position: LatLng(3.7844, 98.6853),
      description: 'Hub Ekspor Kopi Sumatera Bagian Utara',
    ),
    ExportPort(
      name: 'Pelabuhan Panjang',
      position: LatLng(-5.4673, 105.3183),
      description: 'Hub Ekspor Kopi Robusta Lampung',
    ),
    ExportPort(
      name: 'Pelabuhan Tanjung Emas',
      position: LatLng(-6.9538, 110.4206),
      description: 'Hub Ekspor Kopi Jawa Tengah',
    ),
    ExportPort(
      name: 'Pelabuhan Tanjung Perak',
      position: LatLng(-7.2023, 112.7303),
      description: 'Hub Ekspor Kopi Jawa Timur & Flores',
    ),
    ExportPort(
      name: 'Pelabuhan Benoa',
      position: LatLng(-8.7456, 115.2167),
      description: 'Hub Ekspor Kopi Bali & NTB',
    ),
    ExportPort(
      name: 'Pelabuhan Makassar',
      position: LatLng(-5.1215, 119.4124),
      description: 'Hub Ekspor Kopi Toraja & Sulawesi',
    ),
    ExportPort(
      name: 'Pelabuhan Jayapura',
      position: LatLng(-2.5333, 140.7167),
      description: 'Hub Ekspor Kopi Wamena & Papua',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _batches = BatchRepository().getAllBatches().where((b) => b.latitude != null && b.longitude != null).toList();
  }

  ExportPort _findNearestPort(LatLng batchPos) {
    const distanceCalc = Distance();
    ExportPort nearest = _exportPorts.first;
    double minDistance = double.infinity;

    for (final port in _exportPorts) {
      final d = distanceCalc.as(LengthUnit.Kilometer, batchPos, port.position);
      if (d < minDistance) {
        minDistance = d;
        nearest = port;
      }
    }
    return nearest;
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const distanceCalc = Distance();
    return distanceCalc.as(LengthUnit.Kilometer, p1, p2);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'exported':
        return AppColors.info;
      case 'sold':
        return const Color(0xFF9C27B0);
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusLat = widget.focusLat;
    final focusLon = widget.focusLon;
    final center = focusLat != null && focusLon != null
        ? LatLng(focusLat, focusLon)
        : const LatLng(-2.5, 118.0); // Center of Indonesia

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Sentra & Rute Ekspor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: _showRoutes ? 'Sembunyikan Rute' : 'Tampilkan Rute',
            icon: Icon(
              _showRoutes ? Icons.alt_route_rounded : Icons.route_outlined,
              color: _showRoutes ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _showRoutes = !_showRoutes),
          ),
          IconButton(
            tooltip: 'Pusatkan Peta',
            icon: const Icon(Icons.my_location_rounded, color: AppColors.accent),
            onPressed: () {
              _mapController.move(center, widget.focusLat != null ? 12.0 : 5.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: widget.focusLat != null ? 12.0 : 5.0,
              minZoom: 3,
              maxZoom: 18,
              onTap: (tapPosition, point) => setState(() => _selectedBatch = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beanorigin.app',
              ),

              // Polyline layer for logistics routes from plantation to port
              if (_showRoutes)
                PolylineLayer(
                  polylines: _batches
                      .where((b) => b.latitude != null && b.longitude != null)
                      .map((batch) {
                    final batchPos = LatLng(batch.latitude ?? 0.0, batch.longitude ?? 0.0);
                    final port = _findNearestPort(batchPos);
                    final isSelected = _selectedBatch?.id == batch.id;
                    final isExported = batch.status == 'exported';

                    return Polyline(
                      points: [batchPos, port.position],
                      color: isSelected
                          ? AppColors.accent
                          : (isExported
                              ? AppColors.info.withValues(alpha: 0.8)
                              : Colors.amber.withValues(alpha: 0.45)),
                      strokeWidth: isSelected ? 4.0 : 2.2,
                    );
                  }).toList(),
                ),

              // Marker Layer for Coffee Plantations
              MarkerLayer(
                markers: [
                  // Coffee origin markers
                  ..._batches
                      .where((b) => b.latitude != null && b.longitude != null)
                      .map((batch) {
                    final color = _getStatusColor(batch.status);
                    final isSelected = _selectedBatch?.id == batch.id;

                    return Marker(
                      point: LatLng(batch.latitude ?? 0.0, batch.longitude ?? 0.0),
                      width: isSelected ? 48 : 38,
                      height: isSelected ? 48 : 38,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedBatch = batch),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.amberAccent : Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('☕', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Export Port Markers
                  ..._exportPorts.map((port) {
                    return Marker(
                      point: port.position,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.directions_boat_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Legend
          Positioned(
            top: 10,
            right: 10,
            child: _buildLegend(),
          ),

          // Selected Batch Card with Logistics Route
          if (_selectedBatch != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildSelectedBatchCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Keterangan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          _buildLegendItem(AppColors.warning, 'Pending Verifikasi'),
          _buildLegendItem(AppColors.success, 'Terverifikasi Mutu'),
          _buildLegendItem(AppColors.info, 'Siap / Sedang Diekspor'),
          const Divider(color: Color(0xFF3D2E22), height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1E88E5),
                ),
                child: const Center(
                  child: Icon(Icons.directions_boat_rounded, color: Colors.white, size: 9),
                ),
              ),
              const SizedBox(width: 5),
              const Text('Pelabuhan Ekspor', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSelectedBatchCard() {
    final batch = _selectedBatch;
    if (batch == null) return const SizedBox.shrink();
    final statusColor = _getStatusColor(batch.status);
    final batchPos = LatLng(batch.latitude ?? 0.0, batch.longitude ?? 0.0);
    final nearestPort = _findNearestPort(batchPos);
    final distanceKm = _calculateDistanceKm(batchPos, nearestPort.position);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D2E22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('☕', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      batch.variety,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${batch.origin} · ${batch.elevationMasl.toInt()} mdpl',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '👨‍🌾 ${batch.farmerName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (batch.cuppingScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${batch.cuppingScore?.toStringAsFixed(1) ?? '-'} SCA',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.bgDark),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      batch.statusDisplayName,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Logistics Route Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rute Ekspor: ${batch.origin} ➔ ${nearestPort.name} (~${distanceKm.toStringAsFixed(0)} km)',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
