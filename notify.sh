#!/bin/bash

# 通知送信スクリプト
# 様々な通知サービスへメッセージを送信する

# 引数の取得
STATUS="$1"      # 状態（成功/失敗）
MESSAGE="$2"     # メインメッセージ
DETAILS="$3"     # 詳細情報
DISCORD_WEBHOOK="$4"  # Discord Webhook URL
SLACK_WEBHOOK="$5"    # Slack Webhook URL

# タイムスタンプ
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# ログ出力関数
function log {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Discordに通知を送信
function send_discord_notification {
    if [ -z "$DISCORD_WEBHOOK" ]; then
        return
    fi
    
    log "Discordへ通知を送信中..."
    
    # 色を設定（成功:緑, 失敗:赤）
    local color="0x00FF00"
    if [ "$STATUS" != "成功" ]; then
        color="0xFF0000"
    fi
    
    # Discord Embeds形式でメッセージを作成
    local json_data=$(cat <<EOF
{
  "embeds": [
    {
      "title": "${STATUS}: ${MESSAGE}",
      "description": "$(echo "$DETAILS" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/\\n/\\\\n/g')",
      "color": ${color},
      "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')",
      "footer": {
        "text": "リトライスクリプト通知"
      }
    }
  ]
}
EOF
)
    
    # Discord Webhookにメッセージを送信
    curl -s -H "Content-Type: application/json" -X POST -d "$json_data" "$DISCORD_WEBHOOK" > /dev/null
    
    if [ $? -eq 0 ]; then
        log "Discord通知を送信しました"
    else
        log "Discord通知の送信に失敗しました"
    fi
}

# Slackに通知を送信
function send_slack_notification {
    if [ -z "$SLACK_WEBHOOK" ]; then
        return
    fi
    
    log "Slackへ通知を送信中..."
    
    # 色を設定（成功:緑, 失敗:赤）
    local color="#00FF00"
    if [ "$STATUS" != "成功" ]; then
        color="#FF0000"
    fi
    
    # Slack Attachments形式でメッセージを作成
    local json_data=$(cat <<EOF
{
  "attachments": [
    {
      "color": "${color}",
      "title": "${STATUS}: ${MESSAGE}",
      "text": "$(echo "$DETAILS" | sed 's/"/\\"/g' | tr '\n' ' ' | sed 's/\\n/\\\\n/g')",
      "footer": "リトライスクリプト通知 | ${TIMESTAMP}",
      "ts": $(date +%s)
    }
  ]
}
EOF
)
    
    # Slack Webhookにメッセージを送信
    curl -s -H "Content-Type: application/json" -X POST -d "$json_data" "$SLACK_WEBHOOK" > /dev/null
    
    if [ $? -eq 0 ]; then
        log "Slack通知を送信しました"
    else
        log "Slack通知の送信に失敗しました"
    fi
}

# 実行
log "通知を送信します: $STATUS - $MESSAGE"
send_discord_notification
send_slack_notification