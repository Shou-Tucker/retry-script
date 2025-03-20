#!/bin/bash

# リトライ用シェルスクリプト
# 使用方法: ./retry.sh [オプション] コマンド
#
# オプション:
#   -r, --retries 回数       リトライ回数 (デフォルト: 5)
#   -i, --interval 秒数      リトライ間隔の秒数 (デフォルト: 10)
#   -b, --backoff 倍率       バックオフの倍率 (デフォルト: 2.0)
#   -m, --max-interval 秒数  最大リトライ間隔の秒数 (デフォルト: 300)
#   -t, --timeout 秒数       コマンドのタイムアウト秒数 (デフォルト: 30)
#   -s, --success-exit コード  成功とみなす終了コード (デフォルト: 0)
#   -v, --verbose           詳細な出力を表示
#   -n, --notify            成功時に通知を送信
#   -d, --discord-webhook URL Discord Webhook URL
#   -a, --slack-webhook URL   Slack Webhook URL
#   -h, --help              ヘルプを表示

# デフォルト値の設定
MAX_RETRIES=5
INTERVAL=10
BACKOFF=2.0
MAX_INTERVAL=300
TIMEOUT=30
SUCCESS_EXIT_CODE=0
VERBOSE=false
NOTIFY=false
DISCORD_WEBHOOK=""
SLACK_WEBHOOK=""
LOG_FILE="/tmp/retry-$(date +%Y%m%d-%H%M%S).log"