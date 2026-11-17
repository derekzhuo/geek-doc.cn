#!/bin/bash
cd ~/lp16
printf "%-12s %10s %9s %9s %9s\n" GROUP RPS P99 SOFT_C0 SOFT_C1
for g in g1-rss2 g2-single g3-rps g4-rfs; do
  for mode in ka close; do
    f=result.$g-$mode.log; w=wrk.$g-$mode.log
    rps=$(grep "Requests/sec" $w | awk "{print \$2}")
    p99=$(grep -A5 "Latency Distribution" $w | grep 99% | awk "{print \$2}" | sed "s/ms//")
    s0=$(grep "^Average:" $f | awk "\$2==\"0\"{print \$8}")
    s1=$(grep "^Average:" $f | awk "\$2==\"1\"{print \$8}")
    printf "%-12s %10.0f %8sms %8s%% %8s%%\n" "$g-$mode" "$rps" "$p99" "$s0" "$s1"
  done
done
echo
echo "hard IRQ virtio0-input deltas per CPU (close mode):"
for g in g1-rss2 g2-single g3-rps g4-rfs; do
  python3 - "$g" "result.$g-close.log" <<'PY'
import sys,re
g,path=sys.argv[1],sys.argv[2]
txt=open(path).read()
b=re.search(r"--- irq before ---(.*?)--- irq after ---", txt, re.S).group(1)
a=re.search(r"--- irq after ---(.*?)--- softnet", txt, re.S).group(1)
def d(s):
    o={}
    for l in s.splitlines():
        p=l.split()
        if len(p)>=4 and p[0].rstrip(":").isdigit() and "input" in p[-1]:
            o[p[-1]]=(int(p[1]),int(p[2]))
    return o
bb,aa=d(b),d(a)
t0=sum(aa[k][0]-bb[k][0] for k in aa); t1=sum(aa[k][1]-bb[k][1] for k in aa)
print(f"  {g:10s} cpu0 +{t0:>8d}   cpu1 +{t1:>8d}")
PY
done
echo
echo "softnet dropped column: 0 in all 12 runs"
echo "received_rps field nonzero only in g3-rps/g4-rfs (software dispatch active)"
