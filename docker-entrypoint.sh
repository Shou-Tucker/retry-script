#!/bin/bash

# Dockerコンテナのエントリーポイント
# バックグラウンド実行とフォアグラウンド実行の両方に対応

# バックグラウンドフラグのデフォルト値
BACKGROUND=false

# ヘルプメッセージの表示
function show_help {
    cat << EOF
Docker コンテナ用エントリーポイント

使用方法: 
  docker run [Docker options] retry-container [options] [command]

オプション:
  --background        バックグラウンドで実行（デタッチモード）
  --help              このヘルプを表示

例:
  docker run retry-container "curl -s https://example.com"
  docker run retry-container --background -r 10 -i 30 "terraform apply -auto-approve"
EOF
    exit 0
}

# コマンドライン引数の解析
RETRY_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --background)
            BACKGROUND=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            RETRY_ARGS+=("$1")
            shift
            ;;
    esac
done

# バックグラウンド実行
if $BACKGROUND; then
    echo "バックグラウンドモードで実行します..."
    /app/retry.sh "${RETRY_ARGS[@]}" > /proc/1/fd/1 2> /proc/1/fd/2 &
    
    # プロセスIDを記録
    RETRY_PID=$!
    echo "リトライプロセスを開始しました（PID: $RETRY_PID）"
    
    # 無限ループで終了せずにコンテナを動かし続ける
    # これはフォアグラウンドプロセスとして動作し、
    # コンテナがDockerによって停止されるのを防ぎます
    echo "コンテナは実行中です。ログを確認するには:"
    echo "docker logs [container_id]"
    
    # PIDファイルを作成
    echo $RETRY_PID > /tmp/retry.pid
    
    # シグナルハンドラの設定
    trap 'kill $RETRY_PID 2>/dev/null; echo "プロセスを終了します"; exit 0' SIGTERM SIGINT
    
    # バックグラウンドプロセスが終了するまで待機
    wait $RETRY_PID
    EXIT_CODE=$?
    
    echo "リトライプロセスが終了しました（終了コード: $EXIT_CODE）"
    exit $EXIT_CODE
    
# フォアグラウンド実行
else
    echo "フォアグラウンドモードで実行します..."
    exec /app/retry.sh "${RETRY_ARGS[@]}"
fi