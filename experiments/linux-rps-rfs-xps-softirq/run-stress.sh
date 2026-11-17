#!/bin/bash
cd ~/lp16
TARGET=http://172.17.16.16:8080/
for g in g2-single g3-rps; do
  sudo -n ./group.sh $g > result.$g.c256.cfg.log 2>&1
  for mode in ka close; do
    tag=$g-c256-$mode
    sudo -n ./sample.sh $tag > result.$tag.log 2>&1 &
    spid=$!
    sleep 1
    if [ $mode = ka ]; then
      ssh loader "wrk -t2 -c256 -d25s --latency $TARGET" | tee wrk.$tag.log
    else
      ssh loader "wrk -t2 -c128 -d25s -H \"Connection: close\" --latency $TARGET" | tee wrk.$tag.log
    fi
    wait $spid
  done
done
echo STRESS_DONE
