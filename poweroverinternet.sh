#!/bin/bash -e
# POWER OVER INTERNET - ryanj/poweroverinternet

## CONFIG
# uplink test address:
REMOTE_SERVER="${REMOTE_SERVER:-google.com}"
REMOTE_PORT="${REMOTE_PORT:-443}"
# hw reset signal out via GPIO:
GPIO_CHIP="${GPIO_CHIP:-gpiochip0}"
GPIO_DOUT_PIN="${GPIO_DOUT_PIN:-21}"
# daemonize, or exit on success?
DIE_HAPPY="${DIE_HAPPY:-false}"
# timers:
IDLE_SECONDS="${IDLE_SECONDS:-60}"
RECOVERY_TIMEOUT_SECONDS="${RECOVERY_TIMEOUT_SECONDS:-600}"
# logging options:
WELCOME_PROMPT="${WELCOME_PROMPT:-true}"
SUPPRESS_EMOJIS="${SUPPRESS_EMOJIS:-false}"
RELEASE_VERSION="${RELEASE_VERSION:-v1.0.1}"
# external metrics reporting:
EXTERNAL_METRICS="${EXTERNAL_METRICS:-false}"
METRICS_URL="${METRICS_URL:-http://example.com/user/repo/success/message?version=v1.0.1}"

## runtime state
if [ "$SUPPRESS_EMOJIS" == "true" ]; then unset EMOJIS; else EMOJIS=true; fi
NET_LATCH="detached"
SECONDS_SINCE_START=$(date +%s)
DOWNTIME_SINCE_START=0

## functions
function print_welcome {
  if [ "$WELCOME_PROMPT" == "true" ]; then
    if [ "$SUPPRESS_EMOJIS" == "true" ]; then
      echo "POWER OVER INTERNET - ${RELEASE_VER}"
    else
      echo "⚡POWER🔃OVER📶INTERNET🔌 - ${RELEASE_VER}"
    fi
    echo "plan:"
    echo "1. ${EMOJIS:+📶🤔 }Check ${REMOTE_SERVER}:${REMOTE_PORT} for availability..."
    echo "2. ${EMOJIS:+⚡🔌 }Send net restart trigger events via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"
  fi
}

function idle_loop {
  if [ "$NET_LATCH" == "detached" ]; then
    echo "${EMOJIS:+📶🖖 }net uplink active"
  else
    if [ "$DEBUG_OUT" == "enabled" ];
    then
      echo "${EMOJIS:+📶🤙 }net uplink active"
    fi
  fi
  NET_LATCH="attached"
  NET_UP_TIME=$(date +%s)

  # sleep for $IDLE_SECONDS before checking the connection again
  if [ "$DEBUG_OUT" == "enabled" ]; then
    echo "${EMOJIS:+🤖💤 }sleeping for ${IDLE_SECONDS}s..."
  fi
  sleep $IDLE_SECONDS
}

function report_success {
  echo "${EMOJIS:+📶✅ }network uplink restored!"
  TIME=$(date +%s)
  DOWNTIME="$(( $TIME - $NET_UP_TIME ))"
  DOWNTIME_SINCE_START="$(( $DOWNTIME_SINCE_START + $DOWNTIME ))"
  UPTIME_SINCE_START="$(( $SECONDS_SINCE_START - $DOWNTIME_SINCE_START ))"
  NET_AVAILABILITY="$(( $UPTIME_SINCE_START / $SECONDS_SINCE_START ))"
  echo "${EMOJIS:+📶🌟 }net connection recovered after ${DOWNTIME} seconds of downtime"
  echo "${EMOJIS:+📶🆙 }net availability: ${NET_AVAILABILITY}"
  if [ "$EXTERNAL_METRICS" == "true" ]; then
    # Report success via $METRICS_URL
    if [ "$DEBUG_OUT" == "enabled" ]; then
      echo "to disable external metrics reporting, set env key EXTERNAL_METRICS=false"
      echo "> curl ${METRICS_URL}?downtime=${DOWNTIME}&availability=${NET_AVAILABILITY}"
    fi
    # TODO: externalize additional details, gh_username?
    curl -ks --show-error $METRICS_URL >/dev/null
  fi
}

function verify_uplink {
  # monitor the connection until $RECOVERY_TIMEOUT_SECONDS has elapsed
  QUITTING_TIME=$(($(date +%s) + $RECOVERY_TIMEOUT_SECONDS))
  while [ "$(date +%s)" -le $QUITTING_TIME ]
  do
    # confirm reconnection of net uplink
    if ! $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1); then
      if [ "$DEBUG_OUT" == "enabled" ]; then
        echo "${EMOJIS:+🤔 }testing uplink..."
      fi
    else
      report_success

      # daemonize or exit on success?
      if [ "$DIE_HAPPY" == "true" ]; then
        exit 0
      else
        break
      fi
    fi
  done
}

function wait_for_reconnect {
  echo "${EMOJIS:+📶✨ }waiting for network uplink to restart..."
  if [ "$DEBUG_OUT" == "enabled" ]; then
    sleep 23
    echo "${EMOJIS:+⏳⏳ }waiting..."
    sleep 15
    echo "${EMOJIS:+⏳ }waiting..."
    sleep 10
    echo "${EMOJIS:+⌛ }waiting..."
    sleep 5
  else
    sleep 53
  fi
  echo "${EMOJIS:+📶📡 }testing uplink..."
}

function issue_hardware_restart {
  # "Have you tried turning it off and on again?"
  NET_LATCH="detached"
  echo "${EMOJIS:+📶❎ }network uplink is unavailable!"
  echo "${EMOJIS:+⚡🔄 }restarting network uplink..."
  if ! $( /usr/bin/gpioset -s 4 --mode=time $GPIO_CHIP $GPIO_DOUT_PIN=1 );
  then
    echo "ERROR: failed to init hw restart sequence via GPIO"
    echo "$@"
    exit 1
  fi
  echo "${EMOJIS:+🔌💫 }net restart trigger issued via ${GPIO_CHIP} pin ${GPIO_DOUT_PIN}"

  # spinner...
  wait_for_reconnect
  # confirm reconnection && report success
  verify_uplink
}

function repair_uplink {
  # confirm outage before issuing restart
  echo "${EMOJIS:+⚠️ ↪️  }lookup failed - trying again..."
  # TODO: loop here until $NET_TIMEOUT_TRIGGER (seconds) is exceeded?
  if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
  then
    echo "${EMOJIS:+👻⏭️  }disregarding failed lookup... "
  else
    issue_hardware_restart
  fi
}

function verify_net_uplink {
  if [ "$DEBUG_OUT" == "enabled" ]; then
    echo "${EMOJIS:+📶📡 }checking uplink..."
  fi

  # watch the line for connectivity issues...
  if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1); then
    # LGTM 🤖👍
    idle_loop
  else
    repair_uplink
  fi
}

# start here:
welcome
while true; do
  verify_net_uplink
done
