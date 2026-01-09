class Stock {
  final String symbol;
  final double quantity;
  final double avgEntryPrice;
  final double currentPrice;
  final double marketValue;
  final double unrealizedPl;

  Stock({
    required this.symbol,
    required this.quantity,
    required this.avgEntryPrice,
    required this.currentPrice,
    required this.marketValue,
    required this.unrealizedPl,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      quantity: (json['qty'] as num).toDouble(),
      avgEntryPrice: (json['avg_entry_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      marketValue: (json['market_value'] as num).toDouble(),
      unrealizedPl: (json['unrealized_pl'] as num).toDouble(),
    );
  }
}
