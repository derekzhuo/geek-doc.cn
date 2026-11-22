#!/usr/bin/env bash
# 从 coverage.dat 分指标统计行/分支/翻转覆盖。
# 数据文件每行形如 C 'f<0x02>...page<0x02>v_line/...<0x02>h<0x02>TOP.counter' 18
# 0x02 是分隔字节，tr 成 | 后按 page 分类、按行尾命中数判零。
set -e
dat="$1"
tr '\002' '|' < "$dat" | grep '^C ' \
    | sed -E 's/.*page[|](v_[a-z]+)\/.* ([0-9]+)$/\1 \2/' \
    | sort \
    | awk '{t[$1]++; if ($2==0) z[$1]++}
           END {for (k in t) printf "  %-9s covered %d/%d  (%.1f%%, zero=%d)\n",
                   k, t[k]-z[k], t[k], 100.0*(t[k]-z[k])/t[k], z[k]+0}'
