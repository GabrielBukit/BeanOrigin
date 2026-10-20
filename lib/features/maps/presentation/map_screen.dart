import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _batches = BatchRepository().getAllBatches().where((b) => b.latitude != null && b.longitude != null).toList();
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
    final center = widget.focusLat != null && widget.focusLon != null
        ? LatLng(widget.focusLat!, widget.focusLon!)
        : const LatLng(-2.5, 118.0); // Center of Indonesia

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Sentra Kopi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
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
              onTap: (_, __) => setState(() => _selectedBatch = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beanorigin.app',
              ),
              MarkerLayer(
                markers: _batches.map((batch) {
                  final color = _getStatusColor(batch.status);
                  return Marker(
                    point: LatLng(batch.latitude!, batch.longitude!),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedBatch = batch),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
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
                }).toList(),
              ),
            ],
          ),

          // Legend
          Positioned(
            top: 10,
            right: 10,
            child: _buildLegend(),
          ),

          // Selected Batch Card
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
          const Text('Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          _buildLegendItem(AppColors.warning, 'Pending'),
          _buildLegendItem(AppColors.success, 'Verified'),
          _buildLegendItem(AppColors.info, 'Exported'),
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
    final batch = _selectedBatch!;
    final statusColor = _getStatusColor(batch.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D2E22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('☕', style: TextStyle(fontSize: 26))),
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
                    '${batch.cuppingScore!.toStringAsFixed(1)} SCA',
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
    );
  }
}
