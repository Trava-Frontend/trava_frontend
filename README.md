# Trava Frontend

Trava ist ein Flutter-basiertes Frontend für die Verwaltung und Visualisierung von Aktienportfolios. Die Anwendung zeigt Aktiencharts, Portfolioübersichten und bietet eine Chat-Funktion.

## Voraussetzungen

- Flutter SDK (min. stable)
- Chrome installiert

## Installation & Start

### 1. Abhängigkeiten installieren

```sh
flutter pub get
```

### 2. Projekt starten

```sh
flutter run -d chrome --web-hostname=localhost --web-port=60010
```

Die App öffnet sich dann unter `http://localhost:60010` im Browser.

## Projektstruktur

```
lib/
├── main.dart                 # Einstiegspunkt der App
├── config.dart               # Konfiguration
├── api/
│   └── chat_api.dart         # Chat-API-Verbindung
├── models/
│   ├── stock.dart            # Stock-Datenmodell
│   └── stock_point.dart      # Datenpunkt für Charts
├── screens/
│   ├── home_screen.dart      # Startbildschirm
│   ├── login_screen.dart     # Login-Seite
│   └── auth_screen.dart      # Authentifizierung
├── widgets/
│   ├── stock_chart.dart      # Aktien-Chart-Komponente
│   ├── chat_widget.dart      # Chat-Widget
│   ├── single_stock_preview.dart
│   ├── all_stocks_preview.dart
│   ├── api_key_button.dart
│   └── dark_mode_switch.dart # Dark Mode Toggle
├── theme/
│   ├── colors.dart           # Farben
│   ├── light_theme.dart      # Helles Theme
│   └── dark_theme.dart       # Dunkles Theme
└── utils/
    ├── user_provider.dart    # Benutzerverwaltung
    ├── theme_provider.dart   # Theme-Verwaltung
    └── test_api_key.dart     # Test-API-Keys

assets/
├── available.json            # Liste verfügbarer Aktien
├── portfolio.json            # Beispiel-Portfolio
└── images/                   # Logos und Icons
```

## Funktionen

- **Aktien-Dashboard**: Übersicht aller gehaltenen Aktien mit Live-Charts
- **Portfolio-Verwaltung**: Anzeige des aktuellen Portfolios mit Gewinn/Verlust
- **Interaktive Charts**: Zoombar, scrollbar Charts für Aktienkurse
- **Chat-Funktion**: Integrierte Chat-Widget für Anfragen
- **Dark Mode**: Umschaltung zwischen hellem und dunklem Theme
- **Authentifizierung**: Login-System für Benutzer

## Entwicklung

### Hot Reload während der Entwicklung

Flutter unterstützt Hot Reload. Speichern Sie eine Datei, und die Änderungen werden sofort im Browser angezeigt.

### Browser-DevTools

Öffnen Sie die Chrome DevTools (F12), um die Performance zu prüfen und Fehler zu debuggen.

## Build für Produktion

```sh
flutter build web --release
```

Die gebauten Dateien befinden sich dann in `build/web/`.

## Deployment

Das Projekt enthält ein Kubernetes-Manifest und Docker-Setup:

- `Dockerfile`: Docker-Image für die Containerisierung
- `k8s/trava-frontend.yaml`: Kubernetes-Deployment-Konfiguration
- `k8s/nginx.conf`: Nginx-Konfiguration für den Web-Server

## Kontakt & Support

Bei Fragen oder Problemen öffnen Sie bitte ein Issue im Repository.
