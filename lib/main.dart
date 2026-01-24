import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/auth_screen.dart';

import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';

import 'utils/theme_provider.dart';
import 'utils/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TRAVA Assistant',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const _AppEntryPoint(),
        '/login': (context) => const LoginScreen(),
        '/auth': (context) => const AuthScreen(),
      },
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        if (uri.path == '/auth') {
          final token = uri.queryParameters['token'];
          return MaterialPageRoute(
            builder: (_) => AuthScreen(token: token),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}

class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(html.window.location.href);
    final token = uri.queryParameters['token'];

    if (token != null) {
      html.window.localStorage['jwt'] = token;
      html.window.history.replaceState(null, '', '/');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (!userProvider.isReady) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userProvider.isLoggedIn) {
          return const LoginScreen();
        }

        return const ChatScreen(title: 'Your Personal Assistant');
      },
    );
  }
}
