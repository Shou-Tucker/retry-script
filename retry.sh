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

# ヘルプメッセージの表示
function show_help {
    cat << EOF
使用方法: $0 [オプション] コマンド

オプション:
  -r, --retries 回数       リトライ回数 (デフォルト: $MAX_RETRIES)
  -i, --interval 秒数      リトライ間隔の秒数 (デフォルト: $INTERVAL)
  -b, --backoff 倍率       バックオフの倍率 (デフォルト: $BACKOFF)
  -m, --max-interval 秒数  最大リトライ間隔の秒数 (デフォルト: $MAX_INTERVAL)
  -t, --timeout 秒数       コマンドのタイムアウト秒数 (デフォルト: $TIMEOUT)
  -s, --success-exit コード  成功とみなす終了コード (デフォルト: $SUCCESS_EXIT_CODE)
  -v, --verbose           詳細な出力を表示
  -n, --notify            成功時に通知を送信
  -d, --discord-webhook URL Discord Webhook URL
  -a, --slack-webhook URL   Slack Webhook URL
  -h, --help              このヘルプを表示

例:
  $0 "curl -s https://example.com"
  $0 -r 10 -i 5 -b 1.5 "wget https://example.com"
  $0 -v -t 60 "ssh user@server.example.com uptime"
EOF
    exit 0
}

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -r|--retries)
            MAX_RETRIES=$2
            shift 2
            ;;
        -i|--interval)
            INTERVAL=$2
            shift 2
            ;;
        -b|--backoff)
            BACKOFF=$2
            shift 2
            ;;
        -m|--max-interval)
            MAX_INTERVAL=$2
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT=$2
            shift 2
            ;;
        -s|--success-exit)
            SUCCESS_EXIT_CODE=$2
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--notify)
            NOTIFY=true
            shift
            ;;
        -d|--discord-webhook)
            DISCORD_WEBHOOK=$2
            shift 2
            ;;
        -a|--slack-webhook)
            SLACK_WEBHOOK=$2
            shift 2
            ;;
        *)
            COMMAND="$@"
            break
            ;;
    esac
done

# コマンドが指定されていない場合はヘルプを表示
if [ -z "$COMMAND" ]; then
    echo "エラー: 実行するコマンドを指定してください。" >&2
    show_help
fi

# ログ出力関数
function log {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 通知送信関数
function send_notification {
    local status="$1"
    local message="$2"
    local details="$3"
    
    # 通知用スクリプトを呼び出し
    if [ -f "/app/notify.sh" ]; then
        /app/notify.sh "$status" "$message" "$details" "$DISCORD_WEBHOOK" "$SLACK_WEBHOOK"
    else
        # Discordに通知
        if [ -n "$DISCORD_WEBHOOK" ]; then
            curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"**$status**: $message\n\`\`\`\n$details\n\`\`\`\"}" "$DISCORD_WEBHOOK" 2>/dev/null
        fi
        
        # Slackに通知
        if [ -n "$SLACK_WEBHOOK" ]; then
            curl -H "Content-Type: application/json" -X POST -d "{\"text\":\"*$status*: $message\n\`\`\`\n$details\n\`\`\`\"}" "$SLACK_WEBHOOK" 2>/dev/null
        fi
    fi
}

# リトライ関数
function retry_command {
    local retry_count=0
    local current_interval=$INTERVAL
    local exit_code=0
    local start_time=$(date +%s)
    
    # ホスト名とプロセスIDを取得
    local hostname=$(hostname)
    local pid=$$

    # ログファイルのヘッダー情報を記録
    log "リトライプロセス開始: PID=$pid on $hostname"
    log "コマンド: $COMMAND"
    log "設定: リトライ回数=$MAX_RETRIES, 間隔=${INTERVAL}秒, バックオフ倍率=${BACKOFF}, 最大間隔=${MAX_INTERVAL}秒"
    
    # コマンドを実行するループ
    while [ $retry_count -le $MAX_RETRIES ]; do
        # 試行回数を表示
        if [ $retry_count -eq 0 ]; then
            log "コマンドを実行します: $COMMAND"
        else
            log "リトライ $retry_count/$MAX_RETRIES (間隔: ${current_interval}秒): $COMMAND"
        fi

        # 詳細出力モードの場合は開始時刻を表示
        if $VERBOSE; then
            log "実行開始"
        fi

        # タイムアウト付きでコマンドを実行
        SECONDS=0
        output=$(timeout $TIMEOUT bash -c "$COMMAND" 2>&1)
        exit_code=$?
        execution_time=$SECONDS

        # 詳細出力モードの場合は終了時刻と実行時間を表示
        if $VERBOSE; then
            log "実行終了 (所要時間: ${execution_time}秒, 終了コード: $exit_code)"
        fi

        # コマンドの出力を表示
        if [ -n "$output" ]; then
            log "コマンド出力:"
            log "$output"
        fi

        # 終了コードをチェック
        if [ $exit_code -eq $SUCCESS_EXIT_CODE ]; then
            log "成功: コマンドは正常に終了しました (終了コード: $exit_code)"
            
            # 成功時に通知
            if $NOTIFY; then
                local success_message="コマンドが成功しました: $COMMAND"
                local details="ホスト: $hostname\nPID: $pid\n実行時間: ${execution_time}秒\n終了コード: $exit_code\n\n出力:\n$output"
                send_notification "成功" "$success_message" "$details"
            fi
            
            break
        elif [ $exit_code -eq 124 ]; then
            log "警告: コマンドはタイムアウトしました (${TIMEOUT}秒)"
        else
            log "エラー: コマンドは失敗しました (終了コード: $exit_code)"
        fi

        # 最大リトライ回数を超えた場合は終了
        if [ $retry_count -ge $MAX_RETRIES ]; then
            log "失敗: 最大リトライ回数 ($MAX_RETRIES) に達しました"
            
            # 最大リトライに達した場合、失敗を通知
            if $NOTIFY; then
                local failure_message="コマンドが失敗しました（最大リトライ回数に到達）: $COMMAND"
                local details="ホスト: $hostname\nPID: $pid\n最大リトライ回数: $MAX_RETRIES\n最終終了コード: $exit_code\n\n最終出力:\n$output"
                send_notification "失敗" "$failure_message" "$details"
            fi
            
            break
        fi

        # リトライ間隔を計算（指数バックオフ）
        current_interval=$(awk "BEGIN { printf \"%.1f\", $current_interval * $BACKOFF }")
        
        # 最大間隔を超えないようにする
        current_interval=$(awk "BEGIN { printf \"%.1f\", ($current_interval > $MAX_INTERVAL) ? $MAX_INTERVAL : $current_interval }")

        log "待機中... ${current_interval}秒"
        sleep $current_interval
        
        # リトライカウントをインクリメント
        retry_count=$((retry_count + 1))
    done

    # 合計実行時間を計算
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    log "合計実行時間: ${total_time}秒"

    return $exit_code
}

# リトライ実行
retry_command
exit_code=$?

# 最終的な結果を表示
if [ $exit_code -eq $SUCCESS_EXIT_CODE ]; then
    log "最終結果: 成功"
    log "ログファイル: $LOG_FILE"
    exit 0
else
    log "最終結果: 失敗 (最終終了コード: $exit_code)"
    log "ログファイル: $LOG_FILE"
    exit $exit_code
fi