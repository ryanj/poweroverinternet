#!/bin/bash
NET_LATCH="detached"
REMOTE_SERVER="google.com"
REMOTE_PORT=443
GPIO_DOUT_PIN=21
GPIO_DEV=gpiochip0
METRICS_SUCCESS_HOST="example.com/user/repo/success/message"

while true; do
# reconnect the line when down
if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
then

  if [ "$NET_LATCH" == "detached" ];
  then
    echo "net uplink active"
  else
    if [ "$DEBUG_OUT" == "enabled" ];
    then
      echo "net uplink active"
    fi
  fi
  NET_LATCH="attached"
  NET_UP_TIME=$(date +%s)

  # sleep for 1min before checking again
  sleep 60

else

  echo "lookup failed - trying again..."
  # confirm the dropped connection with additional testing
  # TODO: loop here until $NET_TIMEOUT_TRIGGER (seconds) is exceeded
  if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
  then
    echo "disregarding failed lookup... :/"

  else
    NET_LATCH="detached"
    echo "network uplink is unavailable!"
    echo "restarting network uplink..."

    /usr/bin/gpioset -s 4 --mode=time $GPIO_DEV $GPIO_DOUT_PIN=1

    # wait 60s for the network uplink to restart...
    echo "restart issued for net uplink"
    echo "waiting 60s for network uplink to restart..."
    sleep 25
    echo "waiting..."
    sleep 15
    echo "waiting..."
    sleep 10
    echo "waiting..."
    sleep 5
    echo "testing uplink..."

    # monitor the connection for the next 15mins (900 seconds)
    QUITTING_TIME=$(($(date +%s) + 900))
    while [ "$(date +%s)" -le $QUITTING_TIME ]
    do

      # test network uplink
      if $(nc -zw3 $REMOTE_SERVER $REMOTE_PORT >/dev/null 2>&1);
      then
        echo "network uplink restored!"
        DOWNTIME=$(($(date +%s) - $NET_UP_TIME))
        echo "net connection recovered after ${DOWNTIME} seconds of downtime"
        break

        # TODO: report success to external METRICS_SUCCESS_HOST

        # TODO: exit with success?
        # this might allow kube to track of the number of recoveries
        # exit 0

      else
        echo "testing uplink..."
      fi

    done
    #give up - try restarting the uplink again...
  fi
fi

done
