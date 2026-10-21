# vc-09 NFA 正则搜索实测复现

## 环境（实测机）

- macOS 26.5.2，Intel Core i7-9750H @ 2.60GHz
- Apple clang version 21.0.0 (clang-2100.1.1.101)，`-O2 -std=c++17`

## 步骤

```bash
clang++ -O2 -std=c++17 -o gen_file gen_file.cpp
clang++ -O2 -std=c++17 -o gen_patho gen_patho.cpp
clang++ -O2 -std=c++17 -o nfa_search nfa_search.cpp
./gen_file    # 生成 /tmp/vc09_big.txt（100MB 随机文本，~90MB 处植入目标）
./gen_patho   # 生成 /tmp/vc09_patho.txt（100MB，大量 200-600 长度 a-run）

./nfa_search /tmp/vc09_big.txt 'needleLiteralTokenQZXW' 3
./nfa_search /tmp/vc09_big.txt 'error.*code.*42' 3
./nfa_search /tmp/vc09_big.txt 'ID[0-9]+X[a-z]+END' 3
./nfa_search /tmp/vc09_patho.txt 'a*a*a*ab' 3
```

每个程序输出两种引擎（朴素回溯 / Thompson NFA 模拟）各轮耗时（毫秒）、命中位置与长度、回溯步数。

## 实测结果（2026-10-15，三轮取中位数）

| 场景 | pattern | NFA 状态数 | 朴素回溯 | NFA 模拟 |
|---|---|---|---|---|
| 良性 100MB，纯字面量 | `needleLiteralTokenQZXW` | 24 | 599.9 ms | 1636.8 ms |
| 良性 100MB，带 `.*` | `error.*code.*42` | 17 | 600.9 ms | 1631.1 ms |
| 良性 100MB，字符类 + `+` | `ID[0-9]+X[a-z]+END` | 12 | 598.8 ms | 1744.6 ms |
| 病理 100MB a-run，无匹配 | `a*a*a*ab` | 10 | 16674.9 ms（触发 5 亿步护栏，错误返回未命中） | 5956.4 ms（正常返回未命中） |

结论：良性文本上朴素逐位置匹配反而快约 2.7×（常数极小）；病理输入下回溯法步数爆炸、且因护栏给出错误答案，NFA 全程有界。教学版 NFA 的价值是「最坏情况可预期」，不是常态更快。
