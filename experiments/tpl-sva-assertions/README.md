# SystemVerilog Assertion 高频模板实验

**对应教程**：https://geek-doc.cn/chip-design/beginner/tpl-sva-assertions.html（上线后生效）

一个自包含的 SystemVerilog 测试台，验证握手保持、同步复位、FIFO 空/满保护和独热授权五个性质断言。`run.sh` 先跑正常路径，再通过 `+INJECT_FAULTS` 故意制造五类违例；两轮都必须以 `RESULT PASS` 结束，第二轮的五个 `EXPECTED_FAIL` 是断言动作块捕获的预期结果。

## 运行

需要支持 SVA 子集的 Verilator 5.020 或兼容版本：

```bash
bash run.sh
```

也可以使用 Docker 镜像：

```bash
docker run --rm -v "$PWD:/work" -w /work geek-eda:0.2 bash run.sh
```

生成物位于 `obj_dir/`。测试台中的注错逻辑只用于确认断言确实会触发，不属于可综合设计模板。
