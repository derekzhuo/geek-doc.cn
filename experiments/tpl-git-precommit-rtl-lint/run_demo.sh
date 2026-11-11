#!/usr/bin/env bash
set -u
D=/tmp/tpl-hook-demo
rm -rf "$D/.git" "$D/latch_demo.v"
cd "$D"
git init -q
git config user.email "demo@example.com"
git config user.name "demo"
mkdir -p .git/hooks
cp /tmp/tpl-hook-src/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

cat > latch_demo.v <<'VEOF'
module latch_demo (
    input  wire en,
    input  wire d,
    output reg  q
);
always @(*) begin
    if (en) q = d;
end
endmodule
VEOF
git add latch_demo.v
echo '--- 第一次提交：存在 latch 风险，应被拦截 ---'
git commit -m "add latch_demo with missing else"
echo "commit rc=$?"

echo '--- 修复 RTL：补 else 分支后重新提交 ---'
cat > latch_demo.v <<'VEOF'
module latch_demo (
    input  wire en,
    input  wire d,
    output reg  q
);
always @(*) begin
    if (en) q = d;
    else    q = 1'b0;
end
endmodule
VEOF
git add latch_demo.v
git commit -m "add latch_demo with else branch"
echo "commit rc=$?"
git log --oneline
