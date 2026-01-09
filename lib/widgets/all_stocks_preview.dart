import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trava_frontend/widgets/single_stock_preview.dart';
import 'package:trava_frontend/api/chat_api.dart';

import '../models/stock.dart';

class AllStocksPreview extends StatelessWidget {
  final TravaApi api = TravaApi();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Stock>>(
      future: api.getPortfolioStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Fehler: ${snapshot.error}'));
        }

        final stocks = snapshot.data!;
        if (stocks.isEmpty) {
          return const Center(child: Text('Keine Positionen'));
        }

        return Column(
          children: [
            sectionHeader("Dein Portfolio"),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: buildStockSections(context, stocks),
                ),
              ),
            ),
          ],
        );
      },
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
            detailRow('Avg. Buy', '\$${stock.avgEntryPrice.toStringAsFixed(2)}'),
            detailRow('Current', '\$${stock.currentPrice.toStringAsFixed(2)}'),
            detailRow('Market Value', '\$${stock.marketValue.toStringAsFixed(2)}'),
            detailRow(
              'Unrealized P/L',
              stock.unrealizedPl.toStringAsFixed(2),
              valueColor:
              stock.unrealizedPl >= 0 ? Colors.green : Colors.red,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
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
    widgets.addAll(winners.map((s) => stockTile(context, s))
    );
  }

  if (losers.isNotEmpty) {
    widgets.add(const SizedBox(height: 12));
    widgets.add(sectionHeader('Verlierer'));
    widgets.addAll(losers.map((s) => stockTile(context, s))
    );
  }

  return widgets;
}
