import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:bean_origin/core/theme/app_theme.dart';
import 'package:bean_origin/core/utils/constants.dart';

class MarketPriceScreen extends StatefulWidget {
  const MarketPriceScreen({super.key});

  @override
  State<MarketPriceScreen> createState() => _MarketPriceScreenState();
}

class _MarketPriceScreenState extends State<MarketPriceScreen> with SingleTickerProviderStateMixin {
  final _amountController = TextEditingController(text: '1');
  String _baseCurrency = 'USD';
  Map<String, double> _rates = {
    'USD': 1.0,
    'IDR': 16920.0,
    'GBP': 0.787,
    'EUR': 0.913,
  };
  String? _error;
  DateTime? _lastUpdated = DateTime.now();
  late AnimationController _refreshAnimController;

  // Simulated coffee price per kg in USD
  static const double _coffeePriceUsd = 5.82;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refreshAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    _refreshAnimController.repeat();

    try {
      final currencies = AppConstants.supportedCurrencies.where((c) => c != _baseCurrency).join(',');
      final url = '${AppConstants.frankfurterBaseUrl}/latest?from=$_baseCurrency&to=$currencies';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _rates = ratesData.map((key, value) => MapEntry(key, (value as num).toDouble()));
            _rates[_baseCurrency] = 1.0;
            _lastUpdated = DateTime.now();
            _error = null;
          });
        }
      }
    } catch (_) {
      // Keep existing rates
    } finally {
      if (mounted) {
        _refreshAnimController.stop();
        _refreshAnimController.reset();
      }
    }
  }

  double _convert(double amount, String from, String to) {
    if (_rates.isEmpty) return 0;
    final fromRate = _rates[from] ?? 1.0;
    final toRate = _rates[to] ?? 1.0;
    // Convert to base then to target
    return amount / fromRate * toRate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harga Pasar Kopi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          RotationTransition(
            turns: _refreshAnimController,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
              onPressed: _fetchRates,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coffee Price Header
            _buildCoffeePriceHeader(),
            const SizedBox(height: 20),

            // Currency Converter
            _buildCurrencyConverter(),
            const SizedBox(height: 20),

            // Exchange Rate Table
            _buildRateCards(),
            const SizedBox(height: 16),

            // Last updated
            if (_lastUpdated != null)
              Center(
                child: Text(
                  'Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(_lastUpdated as DateTime)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(fontSize: 11, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // API Credit
            _buildApiCredit(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeePriceHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E2218), Color(0xFF3D2E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A4633), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('☕', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Green Bean Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Arabika Specialty (per kg)',
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Price in all currencies
          if (_rates.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: AppConstants.supportedCurrencies.map((currency) {
                final price = _convert(_coffeePriceUsd, 'USD', currency);
                final formatted = _formatCurrency(price, currency);
                return _buildPriceChip(currency, formatted, _getCurrencyFlag(currency));
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceChip(String currency, String price, String flag) {
    return Column(
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          currency,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyConverter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D2E22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_exchange_rounded, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Konversi Mata Uang',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount input + base currency
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    hintText: '1',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3D2E22)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _baseCurrency,
                      dropdownColor: AppColors.bgCard,
                      isExpanded: true,
                      items: AppConstants.supportedCurrencies.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${_getCurrencyFlag(c)} $c',
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _baseCurrency = v ?? 'USD');
                        _fetchRates();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Converted amounts
          if (_rates.isNotEmpty)
            ...AppConstants.supportedCurrencies.where((c) => c != _baseCurrency).map((currency) {
              final amount = double.tryParse(_amountController.text) ?? 1;
              final converted = _convert(amount, _baseCurrency, currency);
              final formatted = _formatCurrency(converted, currency);
              return _buildConversionRow(currency, formatted);
            }),
        ],
      ),
    );
  }

  Widget _buildConversionRow(String currency, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(_getCurrencyFlag(currency), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(
              currency,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCards() {
    if (_rates.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Kurs Terkini (1 USD)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: AppConstants.supportedCurrencies.where((c) => c != 'USD').map((currency) {
            final rate = _convert(1, 'USD', currency);
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D2E22)),
                ),
                child: Column(
                  children: [
                    Text(_getCurrencyFlag(currency), style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(
                      currency,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(rate, currency),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApiCredit() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Data kurs dari Frankfurter API (European Central Bank)',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrencyFlag(String currency) {
    switch (currency) {
      case 'IDR':
        return '🇮🇩';
      case 'USD':
        return '🇺🇸';
      case 'GBP':
        return '🇬🇧';
      case 'EUR':
        return '🇪🇺';
      default:
        return '💰';
    }
  }

  String _formatCurrency(double amount, String currency) {
    if (currency == 'IDR') {
      return NumberFormat('#,##0', 'id').format(amount);
    }
    return NumberFormat('#,##0.00').format(amount);
  }
}
