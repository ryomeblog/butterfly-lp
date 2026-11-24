# バタフライLP の Web 版と共有サーバー（設計書 3.12）。
# リポジトリのルートで：docker build -f server/Dockerfile -t butterfly-lp .
#                     docker run -p 8080:8080 -v lp-share:/data butterfly-lp

# 1. Web 版を作る
FROM ghcr.io/cirruslabs/flutter:3.47.9 AS web
WORKDIR /src
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# 2. サーバーを1つの実行ファイルにする
FROM dart:stable AS server
WORKDIR /srv
COPY server/pubspec.yaml ./
RUN dart pub get
COPY server/ ./
RUN dart pub get --offline && dart compile exe bin/server.dart -o /srv/lp-server

# 3. 実行用
FROM scratch
COPY --from=server /runtime/ /
COPY --from=server /srv/lp-server /app/lp-server
COPY --from=web /src/build/web /app/web
ENV WEB_DIR=/app/web DATA_DIR=/data PORT=8080
VOLUME /data
EXPOSE 8080
CMD ["/app/lp-server"]
