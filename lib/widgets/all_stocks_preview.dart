import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trava_frontend/api/chat_api.dart';

import '../models/stock.dart';

class AllStocksPreview extends StatefulWidget {
  const AllStocksPreview({super.key});

  @override
  State<AllStocksPreview> createState() => _AllStocksPreviewState();
}

class _AllStocksPreviewState extends State<AllStocksPreview> {
  final TravaApi api = TravaApi();
  List<Stock>? _stocks;
  List<Map<String, dynamic>> _pendingOrders = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadPortfolio();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    try {
      final results = await Future.wait([
        api.getPortfolioStocks(),
        api.getPendingOrders(),
      ]);

      final stocks = results[0] as List<Stock>;
      final orders = results[1] as List<Map<String, dynamic>>;

      print(
        'Portfolio loaded: ${stocks.length} positions, ${orders.length} pending orders',
      );

      if (mounted) {
        setState(() {
          _stocks = stocks;
          _pendingOrders = orders;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      print('Portfolio load error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    final success = await api.cancelOrder(orderId);
    if (success) {
      _loadPortfolio();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stocks == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _stocks == null) {
      return Center(child: Text('Fehler: $_error'));
    }

    final stocks = _stocks ?? [];
    final hasPending = _pendingOrders.isNotEmpty;
    final hasPositions = stocks.isNotEmpty;

    if (!hasPositions && !hasPending) {
      return const Center(child: Text('Keine Positionen'));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            sectionHeader("Dein Portfolio"),
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() => _isLoading = true);
                      _loadPortfolio();
                    },
              tooltip: 'Aktualisieren',
            ),
          ],
        ),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Pending Orders Section
                if (hasPending) ...[
                  _buildPendingOrdersSection(),
                  const SizedBox(height: 16),
                ],
                // Portfolio Positions
                ...buildStockSections(context, stocks),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              'Ausstehende Orders (${_pendingOrders.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._pendingOrders.map((order) => _buildPendingOrderTile(order)),
      ],
    );
  }

  Widget _buildPendingOrderTile(Map<String, dynamic> order) {
    final symbol = order['symbol'] ?? '?';
    final qty = order['qty'] ?? 0;
    final side = order['side'] ?? '';
    final status = order['status'] ?? '';
    final orderId = order['id'] ?? '';

    final isBuy = side == 'buy';
    final sideColor = isBuy ? Colors.green : Colors.red;
    final sideIcon = isBuy ? Icons.arrow_upward : Icons.arrow_downward;
    final sideText = isBuy ? 'KAUF' : 'VERKAUF';

    String statusText;
    Color statusColor;
    switch (status) {
      case 'new':
      case 'pending_new':
        statusText = 'Wartend';
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusText = 'Akzeptiert';
        statusColor = Colors.blue;
        break;
      case 'partially_filled':
        statusText = 'Teilweise';
        statusColor = Colors.purple;
        break;
      default:
        statusText = status;
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.orange.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: sideColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(sideIcon, color: sideColor, size: 18),
        ),
        title: Row(
          children: [
            Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: sideColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sideText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: sideColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('Menge: $qty', style: const TextStyle(fontSize: 12)),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                onPressed: () => _cancelOrder(orderId),
                tooltip: 'Stornieren',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                splashRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showStockDetails(BuildContext context, Stock stock) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(stock.symbol),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow('Quantity', stock.quantity.toString()),
            detailRow(
              'Avg. Buy',
              '\$${stock.avgEntryPrice.toStringAsFixed(2)}',
            ),
            detailRow('Current', '\$${stock.currentPrice.toStringAsFixed(2)}'),
            detailRow(
              'Market Value',
              '\$${stock.marketValue.toStringAsFixed(2)}',
            ),
            detailRow(
              'Unrealized P/L',
              stock.unrealizedPl.toStringAsFixed(2),
              valueColor: stock.unrealizedPl >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Widget detailRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    ),
  );
}

Widget stockTile(BuildContext context, Stock stock) {
  final isPositive = stock.unrealizedPl >= 0;
  final color = isPositive ? Colors.green : Colors.red;
  final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        stock.symbol,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Qty: ${stock.quantity} · Buy: \$${stock.avgEntryPrice.toStringAsFixed(2)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${stock.unrealizedPl.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${stock.marketValue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      onTap: () => showStockDetails(context, stock),
    ),
  );
}

Widget sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
  );
}

List<Widget> buildStockSections(BuildContext context, List<Stock> stocks) {
  final winners = stocks.where((s) => s.unrealizedPl >= 0).toList();
  final losers = stocks.where((s) => s.unrealizedPl < 0).toList();

  List<Widget> widgets = [];

  if (winners.isNotEmpty) {
    widgets.add(sectionHeader('Gewinner'));
    widgets.addAll(winners.map((s) => stockTile(context, s)));
  }

  if (losers.isNotEmpty) {
    widgets.add(const SizedBox(height: 12));
    widgets.add(sectionHeader('Verlierer'));
    widgets.addAll(losers.map((s) => stockTile(context, s)));
  }

  return widgets;
}
