enum AssetType { stock, etf, crypto }

class Stock {
  final String symbol;
  final double quantity;
  final double avgEntryPrice;
  final double currentPrice;
  final double marketValue;
  final double unrealizedPl;
  final AssetType assetType;

  Stock({
    required this.symbol,
    required this.quantity,
    required this.avgEntryPrice,
    required this.currentPrice,
    required this.marketValue,
    required this.unrealizedPl,
    this.assetType = AssetType.stock,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'],
      quantity: (json['qty'] as num).toDouble(),
      avgEntryPrice: (json['avg_entry_price'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
      marketValue: (json['market_value'] as num).toDouble(),
      unrealizedPl: (json['unrealized_pl'] as num).toDouble(),
      assetType: _parseAssetType(json['asset_type'] ?? json['symbol']),
    );
  }

  static AssetType _parseAssetType(String? typeOrSymbol) {
    if (typeOrSymbol == null) return AssetType.stock;
    final lower = typeOrSymbol.toLowerCase();
    if (lower == 'etf') return AssetType.etf;
    if (lower == 'crypto') return AssetType.crypto;
    if (typeOrSymbol.contains('/')) return AssetType.crypto;
    return AssetType.stock;
  }

  bool get isCrypto => assetType == AssetType.crypto;
  bool get isETF => assetType == AssetType.etf;
  bool get isStock => assetType == AssetType.stock;
}

class Asset {
  final String symbol;
  final String name;
  final AssetType type;
  final String? category;
  final String? exchange;
  final double? price;
  final bool tradeable;

  Asset({
    required this.symbol,
    required this.name,
    required this.type,
    this.category,
    this.exchange,
    this.price,
    this.tradeable = true,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      symbol: json['symbol'],
      name: json['name'] ?? json['symbol'],
      type: _parseType(json['type']),
      category: json['category'],
      exchange: json['exchange'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      tradeable: json['tradeable'] ?? true,
    );
  }

  static AssetType _parseType(String? type) {
    if (type == null) return AssetType.stock;
    switch (type.toLowerCase()) {
      case 'etf':
        return AssetType.etf;
      case 'crypto':
        return AssetType.crypto;
      default:
        return AssetType.stock;
    }
  }
}
