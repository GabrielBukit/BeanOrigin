import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/bloc/batch_bloc.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedVariety;
  String? _selectedOrigin;
  String? _selectedStatus;
  bool _showFilters = false;
  late AnimationController _filterAnimController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimController,
      curve: Curves.easeInOutCubic,
    );
    context.read<BatchBloc>().add(BatchLoadAll());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _filterAnimController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    context.read<BatchBloc>().add(BatchSearch(
          query: _searchController.text,
          variety: _selectedVariety,
          origin: _selectedOrigin,
          status: _selectedStatus,
        ));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedVariety = null;
      _selectedOrigin = null;
      _selectedStatus = null;
    });
    context.read<BatchBloc>().add(BatchLoadAll());
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimController.forward();
    } else {
      _filterAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Explorer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? AppColors.accent : AppColors.textSecondary,
            ),
            onPressed: _toggleFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari varietas, asal, petani...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Filter Chips
          SizeTransition(
            sizeFactor: _filterAnimation,
            child: _buildFilterSection(),
          ),

          // Batch List
          Expanded(
            child: BlocBuilder<BatchBloc, BatchState>(
              builder: (context, state) {
                if (state is BatchLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (state is BatchError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(state.message, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                if (state is BatchLoaded) {
                  if (state.batches.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildBatchList(state.batches);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-batch');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Batch Baru'),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          const Text('Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              _buildFilterChip('Semua', null, _selectedStatus == null, (v) {
                setState(() => _selectedStatus = null);
                _applyFilters();
              }),
              _buildFilterChip('Pending', 'pending', _selectedStatus == 'pending', (v) {
                setState(() => _selectedStatus = v ? 'pending' : null);
                _applyFilters();
              }),
              _buildFilterChip('Verified', 'verified', _selectedStatus == 'verified', (v) {
                setState(() => _selectedStatus = v ? 'verified' : null);
                _applyFilters();
              }),
              _buildFilterChip('Exported', 'exported', _selectedStatus == 'exported', (v) {
                setState(() => _selectedStatus = v ? 'exported' : null);
                _applyFilters();
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Variety Dropdown
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Varietas',
                  _selectedVariety,
                  ['', ...AppConstants.coffeeVarieties],
                  (v) {
                    setState(() => _selectedVariety = v?.isEmpty == true ? null : v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  'Asal',
                  _selectedOrigin,
                  ['', ...AppConstants.coffeeOrigins],
                  (v) {
                    setState(() => _selectedOrigin = v?.isEmpty == true ? null : v);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Clear filters
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected, Function(bool) onSelected) {
    final statusColors = {
      'pending': AppColors.warning,
      'verified': AppColors.success,
      'exported': AppColors.info,
    };
    final color = value != null ? statusColors[value] ?? AppColors.accent : AppColors.accent;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) => onSelected(v),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: BorderSide(color: isSelected ? color : const Color(0xFF3D2E22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value ?? '',
      dropdownColor: AppColors.bgCard,
      isExpanded: true,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item.isEmpty ? 'Semua' : item,
            style: TextStyle(
              fontSize: 13,
              color: item.isEmpty ? AppColors.textHint : AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.accent.withValues(alpha: 0.4), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada batch ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba ubah filter atau tambahkan batch baru',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList(List<BatchModel> batches) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: batches.length,
      itemBuilder: (context, index) {
        return _BatchCard(
          batch: batches[index],
          index: index,
          onTap: () => Navigator.of(context).pushNamed('/batch-detail', arguments: batches[index]),
        );
      },
    );
  }
}

class _BatchCard extends StatefulWidget {
  final BatchModel batch;
  final int index;
  final VoidCallback onTap;

  const _BatchCard({required this.batch, required this.index, required this.onTap});

  @override
  State<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends State<_BatchCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final statusColor = _getStatusColor(batch.status);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3D2E22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  children: [
                    // Coffee Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(child: Text('☕', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.variety,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  batch.origin,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.terrain_rounded, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Text(
                                '${batch.elevationMasl.toInt()} mdpl',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        batch.statusDisplayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Bottom Row — metadata
                Row(
                  children: [
                    _buildTag('🌱', batch.process),
                    const SizedBox(width: 8),
                    _buildTag('👨‍🌾', batch.farmerName),
                    const Spacer(),
                    if (batch.cuppingScore != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${batch.cuppingScore?.toStringAsFixed(1) ?? '-'} SCA',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bgDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 130),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
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
}
