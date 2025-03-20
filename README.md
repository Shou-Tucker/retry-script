# リトライスクリプト利用ガイド

このプロジェクトは、コマンドを自動的にリトライし、成功時に通知を送信するシェルスクリプトとDockerコンテナを提供します。OCIのA1インスタンス取得など、一時的な障害が発生する可能性があるコマンドの実行に最適です。

## 機能

- **自動リトライ**: 設定可能な回数と間隔でコマンドを自動的にリトライ
- **指数バックオフ**: サーバー負荷を軽減するためにリトライ間隔を徐々に増加
- **タイムアウト管理**: 長時間実行されるコマンドを自動的に終了
- **通知機能**: Discord/Slack Webhookを使用して成功または失敗を通知
- **バックグラウンド実行**: Dockerコンテナを使用してバックグラウンドで実行可能
- **詳細なログ記録**: すべての動作をログファイルに記録

## LINE Notifyの代替サービス

LINE Notifyは2024年7月に終了するため、代わりに以下のサービスを使用できます：

1. **Discord Webhook**: 
   - 無料で使いやすい
   - リッチなフォーマット（色付け、埋め込み）が可能
   - 設定方法: Discordサーバーの「サーバー設定」→「インテグレーション」→「ウェブフック」

2. **Slack Webhook**:
   - 企業での利用に適している
   - 多くのサービスと連携可能
   - 設定方法: Slackワークスペースの「設定とメンテナンス」→「アプリ」→「Incoming Webhooks」

3. **Telegram Bot**:
   - 個人利用に最適
   - シンプルな設定
   - 設定方法: BotFatherでボットを作成し、API Tokenを取得

このリポジトリでは現在、Discord WebhookとSlack Webhookをサポートしています。必要に応じて他の通知サービスも追加できます。

## セットアップ方法

### 1. 単体スクリプトとして使用

```bash
# スクリプトをダウンロード
wget https://raw.githubusercontent.com/Shou-Tucker/retry-script/main/retry.sh

# 実行権限を付与
chmod +x retry.sh

# スクリプトの使用例
./retry.sh -r 10 -i 5 -t 60 "curl -s https://example.com"

# 通知機能を使用
./retry.sh -r 10 -i 5 -n -d "https://discord.com/api/webhooks/your-webhook-url" "terraform apply -auto-approve"
```

### 2. Dockerを使用してバックグラウンドで実行

```bash
# リポジトリをクローン
git clone https://github.com/Shou-Tucker/retry-script.git
cd retry-script

# イメージをビルド
docker build -t retry-container .

# 基本的な使用法
docker run retry-container "curl -s https://example.com"

# バックグラウンドで実行
docker run -d retry-container --background -r 20 -i 30 -n -d "your-discord-webhook-url" "terraform apply -auto-approve"

# 環境変数と共有ボリュームを使用
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -v $(pwd)/terraform:/app/terraform \
  retry-container --background -r 30 -i 60 -n -d "your-discord-webhook" "cd /app/terraform && terraform apply -auto-approve"
```

### 3. Docker Composeを使用する

```bash
# リポジトリをクローン
git clone https://github.com/Shou-Tucker/retry-script.git
cd retry-script

# 設定ファイルを編集
# docker-compose.ymlを編集して、実行するコマンドとWebhook URLを設定します

# 環境変数としてWebhook URLを設定
export DISCORD_WEBHOOK=https://discord.com/api/webhooks/your-webhook-url
export SLACK_WEBHOOK=https://hooks.slack.com/services/your-slack-webhook

# コンテナを起動
docker-compose up -d

# ログを確認
docker-compose logs -f
```

## OCI A1インスタンス取得の例

このスクリプトは、Terraform を使用してOCIのA1インスタンスを取得するシナリオに最適です。以下に例を示します：

```bash
# Docker Compose設定例（docker-compose.yml）
version: '3'

services:
  retry:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: oci-instance-retry
    environment:
      - TZ=Asia/Tokyo
      - TF_VAR_tenancy_ocid=${TF_VAR_tenancy_ocid}
      - TF_VAR_user_ocid=${TF_VAR_user_ocid}
      - TF_VAR_fingerprint=${TF_VAR_fingerprint}
      - TF_VAR_private_key_path=/root/.oci/private.pem
    volumes:
      - ./terraform:/app/terraform
      - ~/.oci:/root/.oci
    command: >
      --background 
      -v 
      -r 100 
      -i 30 
      -b 1.5 
      -m 300 
      -t 600 
      -n
      -d ${DISCORD_WEBHOOK}
      "cd /app/terraform && terraform apply -auto-approve"
```

このコンフィグレーションでは、OCIのA1インスタンスが利用可能になるまで最大100回のリトライを行い、成功するとDiscordで通知します。

## オプションとパラメータ

リトライスクリプト (`retry.sh`) は以下のオプションをサポートしています：

| オプション | 説明 | デフォルト値 |
|----------|------|------------|
| `-r, --retries` | リトライ回数 | 5 |
| `-i, --interval` | 初期リトライ間隔（秒） | 10 |
| `-b, --backoff` | バックオフ倍率 | 2.0 |
| `-m, --max-interval` | 最大リトライ間隔（秒） | 300 |
| `-t, --timeout` | コマンドのタイムアウト（秒） | 30 |
| `-s, --success-exit` | 成功とみなす終了コード | 0 |
| `-v, --verbose` | 詳細な出力を表示 | - |
| `-n, --notify` | 成功時に通知を送信 | - |
| `-d, --discord-webhook` | Discord Webhook URL | - |
| `-a, --slack-webhook` | Slack Webhook URL | - |
| `-h, --help` | ヘルプを表示 | - |

## ログと監視

リトライスクリプトは詳細なログを生成し、実行状況を監視できます：

- ログファイルは `/tmp/retry-[timestamp].log` に保存されます
- Dockerコンテナで実行する場合、`docker logs [container_id]` でログを確認できます
- Docker Composeを使用する場合、`docker-compose logs -f` でログをフォローできます

## 注意点

- バックグラウンドで実行する場合、ホストシステムのリソースを監視することをお勧めします
- 非常に長時間実行されるコマンドの場合、システムの再起動などに注意が必要です
- センシティブな認証情報は環境変数として渡すことをお勧めします

## トラブルシューティング

一般的な問題と解決策：

1. **通知が送信されない**
   - Webhook URLが正しいか確認してください
   - ネットワーク接続を確認してください

2. **Dockerコンテナが予期せず終了する**
   - ログを確認してメモリ不足などのエラーがないか確認してください
   - コンテナのリソース制限を緩和してみてください

3. **コマンドが常にタイムアウトする**
   - `-t` オプションでタイムアウト時間を増やしてください

## 貢献

問題の報告やプルリクエストは大歓迎です。このプロジェクトをさらに改善するためのご提案をお待ちしています。

## ライセンス

MIT