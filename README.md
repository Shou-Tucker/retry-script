# リトライスクリプト利用ガイド

このプロジェクトは、コマンドを自動的にリトライし、成功時に通知を送信するシェルスクリプトとDockerコンテナを提供します。OCIのA1インスタンス取得など、一時的な障害が発生する可能性があるコマンドの実行に最適です。

## 機能

- **自動リトライ**: 設定可能な回数と間隔でコマンドを自動的にリトライ（無限リトライ対応）
- **指数バックオフ**: サーバー負荷を軽減するためにリトライ間隔を徐々に増加
- **タイムアウト管理**: 長時間実行されるコマンドを自動的に終了
- **通知機能**: Discord/Slack Webhookを使用して成功または失敗を通知
- **バックグラウンド実行**: Dockerコンテナを使用してバックグラウンドで実行可能
- **詳細なログ記録**: すべての動作をログファイルに記録
- **複数ユーザー対応**: 最大5ユーザーの認証情報を環境変数で管理可能

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

# 無限リトライを使用
./retry.sh -r 0 -i 5 -t 60 "curl -s https://example.com"

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

# バックグラウンドで実行（無限リトライ）
docker run -d retry-container --background -r 0 -i 30 -n -d "your-discord-webhook-url" "terraform apply -auto-approve"

# 環境変数と共有ボリュームを使用
docker run -d \
  -e AWS_ACCESS_KEY_ID=your-key \
  -e AWS_SECRET_ACCESS_KEY=your-secret \
  -v $(pwd)/terraform:/app/terraform \
  retry-container --background -r 0 -i 60 -n -d "your-discord-webhook" "cd /app/terraform && terraform apply -auto-approve"
```

### 3. Docker Composeを使用する（単一ユーザー）

```bash
# リポジトリをクローン
git clone https://github.com/Shou-Tucker/retry-script.git
cd retry-script

# .env.exampleをコピーして.envを作成
cp .env.example .env

# 設定ファイルを編集
# .envファイルを編集して、認証情報とWebhook URLを設定します
nano .env

# コンテナを起動
docker-compose up -d

# ログを確認
docker-compose logs -f
```

### 4. Docker Composeを使用する（複数ユーザー）

5つのユーザーアカウントを使用して同時にリトライを実行できます：

```bash
# リポジトリをクローン
git clone https://github.com/Shou-Tucker/retry-script.git
cd retry-script

# .env.exampleをコピーして.envを作成
cp .env.example .env

# 設定ファイルを編集
# .envファイルを編集して、5つのユーザーの認証情報とWebhook URLを設定します
nano .env

# マルチユーザー用のDocker Composeを使用
docker-compose -f docker-compose-multi-users.yml up -d

# ログを確認
docker-compose -f docker-compose-multi-users.yml logs -f

# 特定のユーザーのログのみ確認
docker-compose -f docker-compose-multi-users.yml logs -f retry-user1
```

## OCI A1インスタンス取得の例

このスクリプトは、Terraform を使用してOCIのA1インスタンスを取得するシナリオに最適です。以下に例を示します：

```bash
# 環境変数を設定
source .env

# A1インスタンスが取得できるまで無限にリトライ
docker-compose -f docker-compose-multi-users.yml up -d
```

このコンフィグレーションでは、5つのユーザーアカウントを使って、A1インスタンスが利用可能になるまで無限にリトライを行い、成功するとDiscordやSlackで通知します。

## オプションとパラメータ

リトライスクリプト (`retry.sh`) は以下のオプションをサポートしています：

| オプション | 説明 | デフォルト値 |
|----------|------|------------|
| `-r, --retries` | リトライ回数（0=無限リトライ） | 5 |
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

## 環境変数ファイル(.env)

複数ユーザー対応モードでは、以下の環境変数を設定できます：

```bash
# ユーザー1〜5の設定
USER1_TENANCY_OCID=your-tenancy-ocid-1
USER1_USER_OCID=your-user-ocid-1
USER1_FINGERPRINT=your-fingerprint-1
USER1_PRIVATE_KEY_PATH=~/.oci/user1/private.pem
USER1_REGION=ap-tokyo-1

# 共通OCI設定
OCI_COMPARTMENT_ID=your-compartment-id
OCI_AVAILABILITY_DOMAIN=your-availability-domain
OCI_SUBNET_ID=your-subnet-id
OCI_IMAGE_ID=your-image-id

# 通知設定
DISCORD_WEBHOOK=https://discord.com/api/webhooks/your-webhook-url
SLACK_WEBHOOK=https://hooks.slack.com/services/your-slack-webhook
```

## ログと監視

リトライスクリプトは詳細なログを生成し、実行状況を監視できます：

- ログファイルは `/tmp/retry-[timestamp].log` に保存されます
- Dockerコンテナで実行する場合、`docker logs [container_id]` でログを確認できます
- Docker Composeを使用する場合、`docker-compose logs -f` でログをフォローできます

## 注意点

- バックグラウンドで実行する場合、ホストシステムのリソースを監視することをお勧めします
- 非常に長時間実行されるコマンドの場合、システムの再起動などに注意が必要です
- センシティブな認証情報は環境変数として渡すことをお勧めします
- 無限リトライを使用する場合は、正常終了条件を明確にしてください

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

4. **複数ユーザーモードでエラーが発生する**
   - 各ユーザーの秘密鍵が正しいパスにあるか確認してください
   - 各ユーザーの環境変数が正しく設定されているか確認してください

## 貢献

問題の報告やプルリクエストは大歓迎です。このプロジェクトをさらに改善するためのご提案をお待ちしています。

## ライセンス

MIT