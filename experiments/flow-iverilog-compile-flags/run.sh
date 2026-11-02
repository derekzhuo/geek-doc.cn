#!/usr/bin/env bash
# iverilog 编译选项对照实验：-g / -I / -D / -P / -o / -Wall
set +e
cd "$(dirname "$0")"
mkdir -p .build

show() {
  echo
  echo "\$ $*"
  "$@"
  echo "exit=$?"
}

echo "==== 1. -g2005 vs -g2012：语言标准 ===="
show iverilog -g2005 -o .build/g.vvp g2012_feat.v
iverilog -g2012 -o .build/g.vvp g2012_feat.v && vvp .build/g.vvp
echo "exit=$?"

echo
echo "==== 2. -I：include 搜索路径 ===="
show iverilog -g2005 -o .build/inc.vvp inc_demo.v
iverilog -g2005 -Ihdrs -o .build/inc.vvp inc_demo.v && vvp .build/inc.vvp
echo "exit=$?"

echo
echo "==== 3. -D：预处理宏 ===="
iverilog -g2005 -o .build/mac.vvp macro_demo.v && vvp .build/mac.vvp
echo "exit=$?"
iverilog -g2005 -DDEBUG -DWIDTH=16 -o .build/mac.vvp macro_demo.v && vvp .build/mac.vvp
echo "exit=$?"

echo
echo "==== 4. -P：顶层参数覆盖 ===="
iverilog -g2005 -s tb_par -o .build/par.vvp param_demo.v && vvp .build/par.vvp
echo "exit=$?"
iverilog -g2005 -s tb_par -Ptb_par.WIDTH=12 -o .build/par.vvp param_demo.v && vvp .build/par.vvp
echo "exit=$?"

echo
echo "==== 5. -o：输出文件名 ===="
( cd .build && iverilog -g2005 ../param_demo.v && echo "默认产物:" && ls a.out && vvp a.out )
echo "exit=$?"
iverilog -g2005 -o .build/sim.vvp param_demo.v && echo "自定义产物:" && ls .build/sim.vvp && vvp .build/sim.vvp
echo "exit=$?"

echo
echo "==== 6. -Wall：打开告警 ===="
show iverilog -g2005 -o .build/w1.vvp warn_demo.v
show iverilog -g2005 -Wall -o .build/w2.vvp warn_demo.v
show iverilog -g2005 -o .build/b1.vvp bind_demo.v
show iverilog -g2005 -Wall -o .build/b2.vvp bind_demo.v
