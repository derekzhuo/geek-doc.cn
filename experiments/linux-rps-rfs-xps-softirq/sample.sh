#!/bin/bash
# usage: sudo sample.sh <tag>; samples 25s
T=$1
echo "##### SAMPLE $T $(date -Is) #####"
grep virtio0 /proc/interrupts > /tmp/irq.before
cat /proc/net/softnet_stat > /tmp/soft.before
mpstat -P ALL 1 25 > /tmp/mpstat.$T.log 2>&1
grep virtio0 /proc/interrupts > /tmp/irq.after
cat /proc/net/softnet_stat > /tmp/soft.after
echo "--- mpstat average ---"; grep -E "Average|CPU" /tmp/mpstat.$T.log
echo "--- irq before ---"; cat /tmp/irq.before
echo "--- irq after ---"; cat /tmp/irq.after
echo "--- softnet before ---"; cat /tmp/soft.before
echo "--- softnet after ---"; cat /tmp/soft.after
echo "--- ss -s ---"; ss -s
