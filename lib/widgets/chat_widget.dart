import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../api/chat_api.dart';
import '../utils/theme_provider.dart';
import '../utils/user_provider.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  ChatWidgetState createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final InMemoryChatController _chatController = InMemoryChatController();
  int _messageId = 0;
  bool _welcomeMessageSent = false;
  bool _chartLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (_welcomeMessageSent || userProvider.username == null) return;

      _welcomeMessageSent = true;

      final chatApi = TravaApi();
      String text;
      try {
        text = await chatApi.getPortfolioSummaryText();
      } catch (_) {
        text = 'Portfolio konnte nicht geladen werden.';
      }

      if (!mounted) return;

      _chatController.insertMessage(
        TextMessage(
          id: 'welcome',
          authorId: 'ai_response',
          createdAt: DateTime.now().toUtc(),
          text: text,
        ),
      );

      if (!mounted) return;

      try {
        final insight = await chatApi.requestPortfolioInsight();

        if (!mounted) return;

        _chatController.insertMessage(
          TextMessage(
            id: 'portfolio-insight',
            authorId: 'ai_response',
            createdAt: DateTime.now().toUtc(),
            text: insight,
          ),
        );
      } catch (_) {
        // Insight loading failed silently
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // ===============================
  // AGENT → CHART POPUP
  // ===============================
  Future<void> _showChartPopup({
    required String symbol,
    required String period,
  }) async {
    if (_chartLoading) return;
    _chartLoading = true;

    try {
      final data = await TravaApi().getStockHistory(symbol, period: period);

      final points = (data['points'] as List?) ?? [];
      if (points.length < 2 || !mounted) return;

      final spots = <FlSpot>[];
      for (int i = 0; i < points.length; i++) {
        final raw = points[i]['c'];
        final y = raw is num ? raw.toDouble() : double.tryParse('$raw');
        if (y != null && y.isFinite) {
          spots.add(FlSpot(i.toDouble(), y));
        }
      }

      if (spots.length < 2) return;
      final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 560,
              height: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$symbol – Kursverlauf ($period)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: minY * 0.995,
                        maxY: maxY * 1.005,
                        minX: 0,
                        maxX: spots.length.toDouble() - 1,

                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                          ),
                        ],

                        lineTouchData: LineTouchData(
                          enabled: true,
                          handleBuiltInTouches: true,

                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            tooltipRoundedRadius: 8,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,

                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final index = spot.x.toInt();

                                if (index < 0 || index >= points.length)
                                  return null;

                                final dt = DateTime.parse(
                                  points[index]['t'],
                                ).toLocal();
                                final dateLabel =
                                    '${dt.day}.${dt.month}.${dt.year}';

                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(2)} \$\n$dateLabel',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),

                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: (maxY - minY) / 4,
                        ),

                        borderData: FlBorderData(show: true),

                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              interval: (maxY - minY) / 4,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toStringAsFixed(2)} \$',
                                  style: const TextStyle(fontSize: 11),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      _chartLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Warte bis das Widget vollständig initialisiert ist
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final chatTheme = themeProvider.isDarkMode
        ? ChatTheme.dark()
        : ChatTheme.light();

    final currentUserName = userProvider.username ?? 'Du';
    final currentUserId = currentUserName;

    return Chat(
      theme: chatTheme,
      chatController: _chatController,
      currentUserId: currentUserId,

      // PFLICHT in flutter_chat_ui 2.9.1
      resolveUser: (UserID id) async {
        return User(
          id: id,
          name: id == currentUserId ? currentUserName : 'TRAVA',
        );
      },

      onMessageSend: (text) async {
        var messageForApi = '$text\n\nsend by Username: $currentUserName';

        _chatController.insertMessage(
          TextMessage(
            id: '${++_messageId}',
            authorId: currentUserId,
            createdAt: DateTime.now().toUtc(),
            text: text,
          ),
        );

        final placeholder = TextMessage(
          id: 'temp-$_messageId',
          authorId: 'ai_response',
          createdAt: DateTime.now().toUtc(),
          text: '…',
        );
        _chatController.insertMessage(placeholder);

        try {
          final reply = await TravaApi().sendMessage(messageForApi);

          try {
            final action = jsonDecode(reply);
            if (action is Map<String, dynamic> &&
                action['type'] == 'SHOW_STOCK_CHART') {
              _chatController.updateMessage(
                placeholder,
                TextMessage(
                  id: '${-_messageId}',
                  authorId: 'ai_response',
                  createdAt: DateTime.now().toUtc(),
                  text: '📈 Kursverlauf wird geöffnet …',
                ),
              );

              await _showChartPopup(
                symbol: action['symbol'],
                period: action['period'] ?? '1W',
              );
              return;
            }
          } catch (_) {}

          _chatController.updateMessage(
            placeholder,
            TextMessage(
              id: '${-_messageId}',
              authorId: 'ai_response',
              createdAt: DateTime.now().toUtc(),
              text: reply,
            ),
          );
        } catch (_) {
          _chatController.updateMessage(
            placeholder,
            TextMessage(
              id: '${-_messageId}',
              authorId: 'ai_response',
              createdAt: DateTime.now().toUtc(),
              text: 'Fehler beim Senden der Nachricht.',
            ),
          );
        }
      },
    );
  }
}
