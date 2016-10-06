#!/bin/bash
if mkdir /tmp/cambot.lock/
then
  mapfile -t models < <(curl -s https://domain.tld/sm-models.txt)
  for m in "${models[@]}"
  do
    cambot-monitor.bash "${m}" "sm"
  done
  unset models
  mapfile -t models < <(curl -s https://domain.tld/mfc-models.txt)
  for m in "${models[@]}"
  do
    cambot-monitor.bash "${m}" "mfc"
  done
  unset models
  mapfile -t models < <(curl -s https://domain.tld/cb-models.txt)
  for m in "${models[@]}"
  do
    cambot-monitor.bash "${m}" "cb"
  done
  unset models
  rmdir /tmp/cambot.lock/
fi
