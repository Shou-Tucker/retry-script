FROM alpine:latest

# 必要なパッケージをインストール
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    ca-certificates \
    tzdata \
    coreutils

# タイムゾーンをJSTに設定
ENV TZ=Asia/Tokyo

# 作業ディレクトリを作成
WORKDIR /app

# スクリプトをコピー
COPY retry.sh /app/
COPY notify.sh /app/
COPY docker-entrypoint.sh /app/

# 実行権限を付与
RUN chmod +x /app/retry.sh /app/notify.sh /app/docker-entrypoint.sh

# エントリーポイントを設定
ENTRYPOINT ["/app/docker-entrypoint.sh"]