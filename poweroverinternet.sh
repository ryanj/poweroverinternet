#!/bin/bash
# POWER OVER INTERNET - ryanj/poweroverinternet

## CONFIG
REMOTE_SERVER="${REMOTE_SERVER:-google.com}"
REMOTE_PORT="${REMOTE_PORT:-443}"
GPIO_CHIP="${GPIO_CHIP:-gpiochip0}"
GPIO_DOUT_PIN="${GPIO_DOUT_PIN:-21}"
IDLE_SECONDS="${IDLE_SECONDS:-60}"
RECOVERY_TIMEOUT_SECONDS="${RECOVERY_TIMEOUT_SECONDS:-600}"
METRICS_URL="${METRICS_URL:-http://example.com/user/repo/success/message}"
EXTERNAL_METRICS="${EXTERNAL_METRICS:-false}"
WELCOME_PROMPT="${WELCOME_PROMPT:-true}"
SUPPRESS_EMOJIS="${SUPPRESS_EMOJIS:-false}"
DIE_HAPPY="${DIE_HAPPY:-false}"
if [ "$SUPPRESS_EMOJIS" == "true" ]; then unset EMOJIS; else EMOJIS=true; fi

if [ "$WELCOME_PROMPT" == "true" ];
then
  echo "plan:"
  echo "1. ${EMOJIS:+📶🤔 }Check ${REMOTE_SERVER}:${REMOTE_PORT} for availability..."
  echo "2. ${EMOJIS:+⚡🔌 }Send net restart trigger events via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"
  if [ "$SUPPRESS_EMOJIS" == "true" ]; then
    echo "POWER OVER INTERNET"
  else
    echo "⚡POWER🔃OVER📶INTERNET🔌"
  fi
fi

NET_LATCH="detached"
while true; do
# reconnect the line when down
if [ "$DEBUG_OUT" == "enabled" ];
then
  echo "${EMOJIS:+📶📡 }checking uplink..."
fi
if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
then

  if [ "$NET_LATCH" == "detached" ];
  then
    echo "${EMOJIS:+📶🖖 }net uplink active"
  else
    if [ "$DEBUG_OUT" == "enabled" ];
    then
      echo "${EMOJIS:+📶🤙 }net uplink active"
    fi
  fi
  NET_LATCH="attached"
  NET_UP_TIME=$(date +%s)

  # sleep for $IDLE_SECONDS before checking the connection
  if [ "$DEBUG_OUT" == "enabled" ];
  then
    echo "${EMOJIS:+🤖💤 }sleeping for ${IDLE_SECONDS}s..."
  fi
  sleep $IDLE_SECONDS

else

  echo "${EMOJIS:+⚠️ ↪️  }lookup failed - trying again..."
  # confirm the dropped connection with additional testing
  # TODO: loop here until $NET_TIMEOUT_TRIGGER (seconds) is exceeded?
  if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
  then
    echo "${EMOJIS:+👻⏭️  }disregarding failed lookup... "

  else
    NET_LATCH="detached"
    echo "${EMOJIS:+📶❌ }network uplink is unavailable!"
    echo "${EMOJIS:+⚡🔃 }restarting network uplink..."
    if ! $( /usr/bin/gpioset -s 4 --mode=time $GPIO_CHIP $GPIO_DOUT_PIN=1 );
    then
      echo "$@"
      #exit 1
    fi
    echo "${EMOJIS:+🔌💫 }net restart trigger issued via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"

    # spinner...
    echo "${EMOJIS:+📶✨ }waiting 60s for network uplink to restart..."
    sleep 23
    echo "${EMOJIS:+⏳⏳ }waiting..."
    sleep 15
    echo "${EMOJIS:+⏳ }waiting..."
    sleep 10
    echo "${EMOJIS:+⌛ }waiting..."
    sleep 5
    echo "${EMOJIS:+📶📡 }testing uplink..."

    # monitor the connection for the next $RECOVERY_TIMEOUT_SECONDS
    QUITTING_TIME=$(($(date +%s) + $RECOVERY_TIMEOUT_SECONDS))
    while [ "$(date +%s)" -le $QUITTING_TIME ]
    do

      # confirm reconnection of net uplink
      if ! $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
      then
	if [ "$DEBUG_OUT" == "enabled" ];
        then
          echo "${EMOJIS:+🤔 }testing uplink..."
        fi
      else
        echo "${EMOJIS:+📶✅ }network uplink restored!"
        TIME=$(date +%s)
        DOWNTIME="$(( $TIME - $NET_UP_TIME ))"
        echo "${EMOJIS:+📶🌟 }net connection recovered after ${DOWNTIME} seconds of downtime"

        # Report success via $METRICS_URL?
        if [ "$EXTERNAL_METRICS" == "true" ];
        then
          #echo "config:EXTERNAL_METRICS=true"
          #echo "> curl ${METRICS_URL}"
          curl -ks --show-error $METRICS_URL >/dev/null
          #echo "to disable external metrics reporting, set env key EXTERNAL_METRICS=false"
        fi

        # daemonize or exit with success?
        if [ "$DIE_HAPPY" == "true" ];
        then
          exit 0
        else
          break
        fi
      fi

    done
  fi
fi

done
