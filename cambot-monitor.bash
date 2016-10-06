#!/bin/bash
model="$1"
csite="$2"
dur="3600"
bitlyapi=""
bitlyname=""

firescan(){

  tempdir=$(mktemp -d)
  cd "$tempdir"
  sudo tcpflow port 1935 &
  tcpid=$!
  sleep 4
  xvfb-run -s '-ac' -a firefox -no-remote -private "${site}${model}" & ff=$!
  sleep 7
  xvfbpid="$(pgrep -o -P "$ff")"
  let sleepy=$RANDOM%10
  let durp=120
  SECONDS=0; while (( "$SECONDS" < "$durp" )) ; do echo "${model} recording for $SECONDS" ; sleep "$sleepy" ; let sleepy=$RANDOM%10 ; done
  while pgrep -f "firefox -no-remote -private ${site}${model}" > /dev/null
  do
    kill -- $(pgrep -f -o "firefox -no-remote -private ${site}${model}")
  done
  kill -- "$ff"
  kill -- "$xvfbpid"
  kill -- "$tcpid"
  killall tcpflow
  while pgrep -U "$(whoami)" firefox > /dev/null
  do
    kill -- $(pgrep -U "$(whoami)" firefox)
  done
  rm -f report.xml xxx.xxx.* ##server ip address in xxx.xxx
  for i in *
  do
    cat "$i" | netcat -l 1935 &>/dev/null &
    netcatID="$!"
    sleep 3
    rtmpdump -r "rtmp://127.0.0.1$PWD/$i" -c 1935 -o "$i.flv" &>/dev/null
    kill "$netcatID"
  done
  mv *.flv sample.flv
  if vcs-1.13.2.bash -i 15 "sample.flv"
  then
    convert -resize 50% "sample.flv.png" "sample.flv.jpg"
    rm sample.flv.png
  else
    ffmpeg -i sample.flv -preset ultrafast -strict -2 sample.mp4
    vcs-1.13.2.bash -i 15 "sample.mp4"
    convert -resize 50% "sample.mp4.png" "sample.mp4.jpg"
    rm sample.mp4.png
  fi
  find "$tempdir" -size -3k -delete
}

imgur(){
  cd "$tempdir"
  for i in *.jpg
  do
    imgur.sh "$i" 2>>/root/imgurlog.txt
  done
  cd /tmp/
  find "$tempdir" -type f -delete
  rmdir "$tempdir"
  rm -rf GeckoChildCrash* xvfb-run.*
}

smcheck(){
  site="http://www.streamate.com/cam/${model}/"
  if curl -s "$site" | grep -i "I'm offline" > /dev/null
  then
    echo "${model} offline $(date)"
    let random=$RANDOM%45
    let sleepy=5+$random
    echo "sleeping $sleepy"
    sleep $sleepy
  else
    echo "${model} online $(date)"
    link="${site}" ##referral code goes here
    urlen=$(urlencode "$link")
    short=$(curl -s "http://api.bitly.com/v3/shorten?login=${bitlyname}&apiKey=${bitlyapi}&longUrl=${urlen}&format=txt")
    firescan
    img="$(imgur)"
    ttytter -hold -status="#sexy #camgirl #${model} is Online #Streamate! $(date) ${short} ${img}"
    let random=$RANDOM%360
    let sleepy=45+$random
    echo "sleeping $sleepy"
    sleep $sleepy
  fi
}


mfccheck(){
  echo "${model}"
  site="http://profiles.myfreecams.com/${model}"
  status=$(curl -s "$site" | grep -e "profileState" | sed -e 's/.*:\"//g' -e 's/\".*//g')
  if [[ "$status" == "Offline" ]]
  then
    echo "${model} MyFreeCams $status (Offline) $(date)"
    let random=$RANDOM%45
    let sleepy=5+$random
    echo "sleeping $sleepy"
    sleep $sleepy
  elif [[ "$status" =~ "Online" ]]
  then
    echo "${model} Online, Status $status $(date)"
    link="${site}"
    urlen=$(urlencode "$link")
    short=$(curl -s "http://api.bitly.com/v3/shorten?login=${bitlyname}&apiKey=${bitlyapi}&longUrl=${urlen}&format=txt")
    site="http://www.myfreecams.com/#"
    firescan
    img="$(imgur)"
    ttytter -hold -status="#camgirl #${model} is Online #MyFreeCams! Current Status: ${status}! $(date) ${short} ${img}"
    #sleep "$dur"
    let random=$RANDOM%360
    let sleepy=45+$random
    echo "sleeping $sleepy"
    sleep $sleepy
  else
    echo "${model} something went wrong $(date)"
  fi
}

cbcheck(){
  echo "${model}"
  site="https://chaturbate.com/${model}/"
  if curl -s "$site" |  grep -i "Room is currently offline" > /dev/null
  then
    echo "${model} chaturbate offline $(date)"
    let random=$RANDOM%45
    let sleepy=5+$random
    echo "sleeping $sleepy"
    sleep $sleepy
  else
    if curl -s "$site" | grep -i "browser"
    then
      echo "Chaturbate is probably in cloudflare mode. ${model} $(date)"
    else
      echo "${model} chaturbate online $(date)"
      link="${site}"
      urlen=$(urlencode "$link")
      short=$(curl -s "http://api.bitly.com/v3/shorten?login=${bitlyname}&apiKey=${bitlyapi}&longUrl=${urlen}&format=txt")
      firescan
      img="$(imgur)"
      ttytter -hold -status="#camgirl #${model} is Online #Chaturbate! $(date) ${short} ${img}"
      let random=$RANDOM%360
      let sleepy=45+$random
      echo "sleeping $sleepy"
      sleep $sleepy
    fi
  fi
}

if [[ "$csite" == "sm" ]]
then
    smcheck
    sleep .5
elif [[ "$csite" == "mfc" ]]
then
    mfccheck
    sleep .5
elif [[ "$csite" == "cb" ]]
then
    cbcheck
    sleep .5
fi
