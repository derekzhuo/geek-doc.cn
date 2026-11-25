# Python 真值表表达式验证

**对应教程**：https://geek-doc.cn/chip-design/beginner/seed-python-truth-table-check.html（教程上线后生效）

这个例子验证 `F(A,B,C)=Σm(1,2,3,5,7)`。需求函数直接由最小项集合实现，与两个待测表达式分别独立。脚本先报告误写式 `C + ¬A¬B` 的首个反例，再验证修正式 `C + ¬AB`，最后执行自校验。

## 运行

只需要 Python 3 标准库，在 Unix 环境执行：

```bash
./run.sh
```

也可以直接执行 `python3 truth_table_check.py`。脚本会输出 m0 错误反例、修正后的八行全量 PASS、排除 m0 后暴露的 m2 反例以及布尔运算与位运算的区别；末尾的 `SELF-CHECK PASS` 表示所有断言均成立。
