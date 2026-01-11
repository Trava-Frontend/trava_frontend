// Shared configuration for API base URL
// Build with: --dart-define ENV=prod for k8s production
// Build with: --dart-define ENV=dev (or omit) for local development
const environment = String.fromEnvironment('ENV', defaultValue: 'dev');

String get apiBaseUrl {
  switch (environment) {
    case 'prod':
      return 'https://trava-n8n.informatik.haw-hamburg.de';
    default:
      return 'http://localhost:8080';
  }
}

Uri apiUrl(String path) {
  final baseUrl = apiBaseUrl;
  if (path.startsWith('/')) return Uri.parse('$baseUrl$path');
  return Uri.parse('$baseUrl/$path');
}
