import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:trava_frontend/models/stock.dart';


import '../config.dart';

class TravaApi {
  // API Base ist build-time konfigurierbar via --dart-define=API_BASE_URL=...
  static final Uri _replyMasterUrl = apiUrl('/api/reply/master');

  Future<String> sendMessage(String message) async {
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
        body: jsonEncode({"query": message}),
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
  final uri = apiUrl('/api/alpaca/summary/text');

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer ${html.window.localStorage['jwt']}',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Portfolio konnte nicht geladen werden');
  }

  final data = jsonDecode(response.body);
  return data['message'] as String;
}

Future<String> requestPortfolioInsight() async {
  final portfolioSummary = await getPortfolioSummaryText();

  final prompt = '''
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
  final uri = apiUrl(
  '/api/market/stock/$symbol'
  '?period=$period',
);

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer ${html.window.localStorage['jwt']}',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Kursdaten konnten nicht geladen werden');
  }

  return jsonDecode(response.body);
}

  Future<List<Stock>> getPortfolioStocks() async {
    final uri = apiUrl('/api/trade/portfolio');
    final token = html.window.localStorage['jwt'];

    if (token == null) {
      throw Exception('Nicht eingeloggt');
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Portfolio konnte nicht geladen werden');
    }

    final data = jsonDecode(response.body);
    final List positions = data['positions'];

    return positions.map((e) => Stock.fromJson(e)).toList();
  }

}