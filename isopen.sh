#!/bin/zsh

# 默认值
TARGET_HOST=""
TARGET_PORT=""
INTERVAL=2
SOUND_FILE="/System/Library/Sounds/Ping.aiff"
SOUND_VOLUME=80

# 帮助信息
usage() {
  echo "Usage: $(basename $0) [host] [port] [-i <interval>] [-s <sound_file>] [-v <volume>] [-?]"
  echo ""
  echo "Options:"
  echo "  host           Target host to check (e.g., 127.0.0.1)"
  echo "  port           Target port to check (e.g., 8080)"
  echo "  -i <interval>  Interval between checks in seconds (default: 2)"
  echo "  -s <sound_file> Path to the sound file to play when the port is open (default: $SOUND_FILE)"
  echo "  -v <volume>    Sound volume (range: 0-100, default: 80)"
  echo "  -?             Show this help message"
  exit 1
}

# 支持直接传递 host 和 port 的模式
if [[ $# -ge 2 && $1 != -* ]]; then
  TARGET_HOST="$1"
  TARGET_PORT="$2"
  shift 2
fi

# 解析选项参数
while getopts "h:p:i:s:v:?" opt; do
  case $opt in
    h)
      TARGET_HOST="$OPTARG"
      ;;
    p)
      TARGET_PORT="$OPTARG"
      ;;
    i)
      INTERVAL="$OPTARG"
      ;;
    s)
      SOUND_FILE="$OPTARG"
      ;;
    v)
      SOUND_VOLUME="$OPTARG"
      if ! [[ "$SOUND_VOLUME" =~ ^[0-9]+$ ]] || ((SOUND_VOLUME < 0 || SOUND_VOLUME > 1000)); then
        echo "Error: Volume must be a number between 0 and 1000."
        exit 1
      fi
      ;;
    ?)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

# 检查是否提供了必要的参数
if [[ -z $TARGET_HOST || -z $TARGET_PORT ]]; then
  echo "Error: Target host and port are required."
  usage
fi

# 检查是否提供的间隔是有效数字
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || ((INTERVAL <= 0)); then
  echo "Error: Interval must be a positive number."
  exit 1
fi

# 检查音效文件是否存在
if [[ ! -f $SOUND_FILE ]]; then
  echo "Error: Sound file '$SOUND_FILE' does not exist."
  exit 1
fi


# 记录当前系统音量，退出时恢复
CURRENT_VOLUME=$(osascript -e "output volume of (get volume settings)")
trap "set_volume $CURRENT_VOLUME" EXIT

# 检测端口
echo "Checking if port $TARGET_PORT on $TARGET_HOST is open every $INTERVAL seconds..."
echo "Sound: $SOUND_FILE | Volume: $SOUND_VOLUME"

while true; do
  nc -z $TARGET_HOST $TARGET_PORT 2>/dev/null
  if [[ $? -eq 0 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Port $TARGET_PORT is open on $TARGET_HOST!"
    afplay -v $SOUND_VOLUME "$SOUND_FILE"  # 播放提示音
  fi
  sleep $INTERVAL
done