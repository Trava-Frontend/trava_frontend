import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:trava_frontend/models/stock.dart';

import '../config.dart';

class TravaApi {
  // API Base ist build-time konfigurierbar via --dart-define=API_BASE_URL=...
  static final Uri _replyMasterUrl = apiUrl('/api/reply/master');

  Future<String> sendMessage(String message, {bool forceMode = false}) async {
    final token = html.window.localStorage['jwt'];

    if (token == null) {
      html.window.location.href = "/#/login";
      return "Nicht eingeloggt.";
    }

    try {
      final response = await http.post(
        _replyMasterUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"query": message, "force_mode": forceMode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "Keine Antwort erhalten.";
      } else if (response.statusCode == 401) {
        html.window.localStorage.remove('jwt');
        html.window.location.href = "/#/login";
        return "Session abgelaufen. Bitte erneut einloggen.";
      } else {
        try {
          final error = jsonDecode(response.body);
          final errorMsg = error["error"]?["message"] ?? response.body;
          return "Fehler ${response.statusCode}: $errorMsg";
        } catch (_) {
          return "Fehler ${response.statusCode}: ${response.body}";
        }
      }
    } catch (e) {
      return "Anfrage fehlgeschlagen: $e";
    }
  }

  Future<String> getPortfolioSummaryText() async {
    final uri = apiUrl('/api/alpaca/summary/text_auth');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${html.window.localStorage['jwt']}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Portfolio konnte nicht geladen werden');
    }

    final data = jsonDecode(response.body);
    return data['message'] as String;
  }

  Future<String> requestPortfolioInsight() async {
    final portfolioSummary = await getPortfolioSummaryText();

    final prompt =
        '''
Hier ist mein aktuelles Portfolio in zusammengefasster Form:

$portfolioSummary

Aufgabe:
Du bist ein vanalytischer Finanzassistent.
Mach nur aussagen die mich konkret betreffen. Ich will keine allgemeinen Ratschläge, sondern konkrete Aussagen zu meinem Portfolio.

1. Analysiere alle Positionen im Portfolio qualitativ.
   - Gruppiere sie grob in: verkaufen, halten, beobachten
   - Nenne nur die Anzahl der Positionen je Kategorie (keine Namen, keine Zahlen)

2. Beziehe das aktuell verfügbare Cash mit ein.
   - Beschreibe allgemein, in welche Marktbereiche oder Sektoren man investieren könnte
   - benutzte nachrichten und trends um sinnvolle aktuelle themen zu nennen. aber du musst sie nicht im text begründen
   - bezieh das aktuelle portfolio mit ein um strategien zu begründen
   
3. Formuliere ein paar prägnante Aussagen zu meinem Portfolio.

4. Jede Aussage muss begründbar sein.

Ausgabeformat:
- Gegliederte Stichpunkte
- Maximal 6 Bulletpoints insgesamt
''';

    return await sendMessage(prompt);
  }

  Future<Map<String, dynamic>> getStockHistory(
    String symbol, {
    String timeframe = '1Hour',
    String period = '1W',
  }) async {
    // Erkennung ob Crypto (enthält / oder endet auf USD bei Crypto-Symbolen)
    final isCrypto =
        symbol.contains('/') ||
        [
          'BTC',
          'ETH',
          'SOL',
          'DOGE',
          'XRP',
          'ADA',
          'LTC',
          'LINK',
          'AVAX',
          'MATIC',
          'DOT',
          'SHIB',
        ].any((c) => symbol.toUpperCase().startsWith(c));

    if (isCrypto) {
      // Crypto symbol normalisieren
      final cryptoSymbol = symbol
          .toUpperCase()
          .replaceAll('/USD', '')
          .replaceAll('USD', '')
          .replaceAll('-', '');
      return await getCryptoHistory(
        cryptoSymbol,
        timeframe: timeframe,
        limit: 100,
      );
    }

    final uri = apiUrl(
      '/api/market/stock/$symbol'
      '?period=$period',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${html.window.localStorage['jwt']}'},
    );

    if (response.statusCode != 200) {
      throw Exception('Kursdaten konnten nicht geladen werden');
    }

    return jsonDecode(response.body);
  }

  Future<List<Stock>> getPortfolioStocks() async {
    final uri = apiUrl('/api/trade/portfolio_auth');
    final token = html.window.localStorage['jwt'];

    if (token == null) {
      throw Exception('Nicht eingeloggt');
    }

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Portfolio konnte nicht geladen werden');
    }

    final data = jsonDecode(response.body);
    final List positions = data['positions'];

    return positions.map((e) => Stock.fromJson(e)).toList();
  }

  /// Fetches all available assets (stocks, ETFs, crypto)
  Future<List<Map<String, dynamic>>> getAllAssets({
    String? assetType,
    String? search,
    bool includePrice = false,
  }) async {
    var path = '/api/assets/all?include_price=$includePrice';
    if (assetType != null) path += '&asset_type=$assetType';
    if (search != null) path += '&search=$search';

    final uri = apiUrl(path);
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Assets konnten nicht geladen werden');
    }

    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Fetches available ETFs
  Future<List<Map<String, dynamic>>> getAvailableETFs({
    String? category,
  }) async {
    var path = '/api/etf/assets';
    if (category != null) path += '?category=$category';

    final uri = apiUrl(path);
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('ETFs konnten nicht geladen werden');
    }

    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Fetches available cryptocurrencies
  Future<List<Map<String, dynamic>>> getAvailableCryptos() async {
    final uri = apiUrl('/api/crypto/assets');
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Kryptos konnten nicht geladen werden');
    }

    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Gets ETF price history
  Future<Map<String, dynamic>> getETFHistory(
    String symbol, {
    String timeframe = '1Day',
    int limit = 100,
  }) async {
    final uri = apiUrl(
      '/api/etf/history/$symbol?timeframe=$timeframe&limit=$limit',
    );
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('ETF-Historie konnte nicht geladen werden');
    }

    return jsonDecode(response.body);
  }

  /// Gets cryptocurrency price history
  Future<Map<String, dynamic>> getCryptoHistory(
    String symbol, {
    String timeframe = '1Hour',
    int limit = 100,
  }) async {
    final uri = apiUrl(
      '/api/crypto/history/$symbol?timeframe=$timeframe&limit=$limit',
    );
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Krypto-Historie konnte nicht geladen werden');
    }

    return jsonDecode(response.body);
  }

  /// Gets cryptocurrency quote
  Future<Map<String, dynamic>> getCryptoQuote(String symbol) async {
    final uri = apiUrl('/api/crypto/quote/$symbol');
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Krypto-Quote konnte nicht geladen werden');
    }

    return jsonDecode(response.body);
  }

  /// Gets ETF quote
  Future<Map<String, dynamic>> getETFQuote(String symbol) async {
    final uri = apiUrl('/api/etf/quote/$symbol');
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('ETF-Quote konnte nicht geladen werden');
    }

    return jsonDecode(response.body);
  }

  /// Searches for assets across all types
  Future<List<Map<String, dynamic>>> searchAssets(
    String query, {
    String? assetType,
  }) async {
    var path = '/api/assets/search?q=$query';
    if (assetType != null) path += '&asset_type=$assetType';

    final uri = apiUrl(path);
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Suche fehlgeschlagen');
    }

    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// Gets asset type counts
  Future<Map<String, dynamic>> getAssetTypes() async {
    final uri = apiUrl('/api/assets/types');
    final token = html.window.localStorage['jwt'];

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Asset-Typen konnten nicht geladen werden');
    }

    return jsonDecode(response.body);
  }
}
