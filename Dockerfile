# Multi-stage build for Flutter Web
# Build stage
# Use a Flutter image with Dart >= 3.9 to satisfy sdk: ^3.9.2
FROM ghcr.io/cirruslabs/flutter:latest AS build
ARG ENV=dev
WORKDIR /app

# Pre-copy pubspec to leverage Docker cache
COPY pubspec.yaml pubspec.lock ./
COPY analysis_options.yaml .
RUN flutter pub get

# Copy the rest
COPY . .
RUN flutter pub get
# Create placeholder .env file (required by pubspec.yaml assets)
RUN touch .env
# Build with ENV=dev (localhost) or ENV=prod (k8s domain URL)
RUN flutter build web --release --dart-define ENV=${ENV} --no-wasm-dry-run

# Runtime stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY --from=build /app/build/web .

# Replace default nginx config for SPA routing
COPY k8s/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
