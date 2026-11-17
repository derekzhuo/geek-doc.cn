#!/bin/bash
cd ~/lp16
TARGET=http://172.17.16.16:8080/
sudo -n ./sample.sh idle > result.idle.log 2>&1
for g in g1-rss2 g2-single g3-rps g4-rfs; do
  sudo -n ./group.sh $g | tee result.$g.cfg.log
  for mode in ka close; do
    tag=$g-$mode
    sudo -n ./sample.sh $tag > result.$tag.log 2>&1 &
    spid=$!
    sleep 1
    if [ $mode = ka ]; then
      ssh loader "wrk -t2 -c128 -d25s --latency $TARGET" | tee wrk.$tag.log
    else
      ssh loader "wrk -t2 -c64 -d25s -H \"Connection: close\" --latency $TARGET" | tee wrk.$tag.log
    fi
    wait $spid
  done
done
echo ALL_DONE
