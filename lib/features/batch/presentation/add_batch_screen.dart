import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';
import 'package:bean_origin/features/auth/bloc/auth_bloc.dart';

class AddBatchScreen extends StatefulWidget {
  const AddBatchScreen({super.key});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _elevationController = TextEditingController();
  final _moistureController = TextEditingController();
  final _notesController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _slopeController = TextEditingController();

  String _selectedVariety = AppConstants.coffeeVarieties.first;
  String _selectedOrigin = AppConstants.coffeeOrigins.first;
  String _selectedProcess = AppConstants.coffeeProcesses.first;
  bool _isLocating = false;

  @override
  void dispose() {
    _weightController.dispose();
    _elevationController.dispose();
    _moistureController.dispose();
    _notesController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _slopeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Layanan lokasi GPS belum aktif di perangkat.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin akses lokasi GPS ditolak.'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak permanen, aktifkan di Pengaturan.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        if (position.altitude > 0 && _elevationController.text.isEmpty) {
          _elevationController.text = position.altitude.toStringAsFixed(0);
        }
        _isLocating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Koordinat berhasil diperoleh: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLocating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membaca GPS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _submitBatch() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    String farmerId = 'user_001';
    String farmerName = 'Petani Kopi';

    if (authState is AuthAuthenticated) {
      farmerId = authState.user.id;
      farmerName = authState.user.name;
    }

    final batch = BatchModel(
      id: 'BATCH-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      farmerId: farmerId,
      farmerName: farmerName,
      variety: _selectedVariety,
      origin: _selectedOrigin,
      process: _selectedProcess,
      elevationMasl: double.tryParse(_elevationController.text) ?? 0,
      moistureContent: double.tryParse(_moistureController.text),
      weightKg: double.tryParse(_weightController.text),
      latitude: double.tryParse(_latController.text),
      longitude: double.tryParse(_lonController.text),
      slopeAngle: double.tryParse(_slopeController.text),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
    );

    context.read<BatchBloc>().add(BatchAdd(batch));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Batch berhasil didaftarkan ke sistem!'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Batch Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Varietas & Asal
              _buildSectionTitle('☕ Informasi Kopi'),
              const SizedBox(height: 12),

              _buildDropdownField(
                'Varietas',
                _selectedVariety,
                AppConstants.coffeeVarieties,
                (v) => setState(() => _selectedVariety = v!),
              ),
              const SizedBox(height: 12),

              _buildDropdownField(
                'Daerah Asal',
                _selectedOrigin,
                AppConstants.coffeeOrigins,
                (v) => setState(() => _selectedOrigin = v!),
              ),
              const SizedBox(height: 12),

              _buildDropdownField(
                'Proses Pascapanen',
                _selectedProcess,
                AppConstants.coffeeProcesses,
                (v) => setState(() => _selectedProcess = v!),
              ),
              const SizedBox(height: 24),

              // Section: Data Teknis
              _buildSectionTitle('📊 Data Teknis & Sensor Lahan'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _elevationController,
                      label: 'Ketinggian (mdpl)',
                      hint: '1500',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      icon: Icons.terrain_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Berat (kg)',
                      hint: '250',
                      keyboardType: TextInputType.number,
                      icon: Icons.scale_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _moistureController,
                      label: 'Kadar Air (%)',
                      hint: '11.5',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.water_drop_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _slopeController,
                      label: 'Kemiringan (°)',
                      hint: '12.0',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.landscape_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Lokasi (LBS Geo-tagging)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('📍 Geo-tag Lokasi Kebun'),
                  TextButton.icon(
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.accent),
                    label: Text(
                      _isLocating ? 'Mencari...' : 'Deteksi GPS',
                      style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latController,
                      label: 'Latitude',
                      hint: '4.6167',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lonController,
                      label: 'Longitude',
                      hint: '96.8333',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Catatan
              _buildSectionTitle('📝 Catatan Tambahan'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Catatan tambahan tentang pemupukan, naungan, atau metode pengolahan batch...',
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _submitBatch,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Simpan & Daftarkan Batch'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.bgCard,
      isExpanded: true,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.coffee_rounded, color: AppColors.accent, size: 20),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.accent, size: 20) : null,
      ),
      validator: validator,
    );
  }
}
