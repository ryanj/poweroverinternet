#!/bin/bash
# POWER OVER INTERNET - ryanj/poweroverinternet

## CONFIG
REMOTE_SERVER="${REMOTE_SERVER:-google.com}"
REMOTE_PORT="${REMOTE_PORT:-443}"
GPIO_CHIP="${GPIO_CHIP:-gpiochip0}"
GPIO_DOUT_PIN="${GPIO_DOUT_PIN:-21}"
IDLE_SECONDS="${IDLE_SECONDS:-60}"
RECOVERY_TIMEOUT_SECONDS="${RECOVERY_TIMEOUT_SECONDS:-600}"
METRICS_SUCCESS_HOST="${METRICS_SUCCESS_HOST:-example.com/user/repo/success/message}"

echo "⚡POWER🔃OVER📶INTERNET🔌"
echo "starting..."
echo ""

echo "> echo ~/.plan"
echo "1. 📶🤔 Check ${REMOTE_SERVER}:${REMOTE_PORT} for availability..."
echo "2. ⚡🔌 Send net restart trigger events via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"
echo ""

echo "status: "
NET_LATCH="detached"
while true; do
# reconnect the line when down
if [ "$DEBUG_OUT" == "enabled" ];
then
  echo "📶📡 checking uplink..."
fi
if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
then

  if [ "$NET_LATCH" == "detached" ];
  then
    echo "📶🖖 net uplink active"
  else
    if [ "$DEBUG_OUT" == "enabled" ];
    then
      echo "📶🤙 net uplink active"
    fi
  fi
  NET_LATCH="attached"
  NET_UP_TIME=$(date +%s)

  # sleep for $IDLE_SECONDS before checking the connection
  if [ "$DEBUG_OUT" == "enabled" ];
  then
    echo "🤖💤 sleeping for ${IDLE_SECONDS}s..."
  fi
  sleep $IDLE_SECONDS

else

  echo "⚠️ ↪️  lookup failed - trying again..."
  # confirm the dropped connection with additional testing
  # TODO: loop here until $NET_TIMEOUT_TRIGGER (seconds) is exceeded?
  if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
  then
    echo "👻⏭️  disregarding failed lookup... "

  else
    NET_LATCH="detached"
    echo "📶❌ network uplink is unavailable!"
    echo "⚡🔃 restarting network uplink..."
    if ! $( /usr/bin/gpioset -s 4 --mode=time $GPIO_CHIP $GPIO_DOUT_PIN=1 );
    then
      echo "$@"
      exit 1
    fi
    echo "🔌💫 net restart trigger issued via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"

    # spinner...
    echo "📶✨ waiting 60s for network uplink to restart..."
    sleep 15
    echo ""
    sleep 10
    echo "⏳⏳ waiting..."
    sleep 15
    echo "⏳ waiting..."
    sleep 10
    echo "⌛ waiting..."
    sleep 4
    echo ""
    sleep 1
    echo "📶📡 testing uplink..."

    # monitor the connection for the next $RECOVERY_TIMEOUT_SECONDS
    QUITTING_TIME=$(($(date +%s) + $RECOVERY_TIMEOUT_SECONDS))
    while [ "$(date +%s)" -le $QUITTING_TIME ]
    do

      # test network uplink
      if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
      then
        echo "📶✅ network uplink restored!"
        DOWNTIME=$(( $(date +%s) - $NET_UP_TIME ))
        echo "📶🌟 net connection recovered after ${DOWNTIME} seconds of downtime"
        break

        # TODO: report success to external METRICS_SUCCESS_HOST

        # TODO: exit with success?
        # this might allow kube to track of the number of recoveries
        # exit 0

      else
        echo "🤔 testing uplink..."
      fi

    done
    #give up 🔃 try restarting the uplink again...
  fi
fi

done
