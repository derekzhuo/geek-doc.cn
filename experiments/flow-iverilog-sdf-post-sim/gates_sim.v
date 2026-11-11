`timescale 1ps/1ps
// 门级仿真模型：为综合网表中实际出现的 7 种 Yosys 通用门提供功能与 specify 路径。
// specify 路径默认延时为 0，延时数字由 counter.sdf 反标注入。
module \$_NOT_ (A, Y);
input A; output Y;
specify (A => Y) = (0,0); endspecify
not g (Y, A);
endmodule

module \$_NAND_ (A, B, Y);
input A, B; output Y;
specify (A => Y) = (0,0); (B => Y) = (0,0); endspecify
nand g (Y, A, B);
endmodule

module \$_OR_ (A, B, Y);
input A, B; output Y;
specify (A => Y) = (0,0); (B => Y) = (0,0); endspecify
or g (Y, A, B);
endmodule

module \$_ANDNOT_ (A, B, Y);
input A, B; output Y;
specify (A => Y) = (0,0); (B => Y) = (0,0); endspecify
assign Y = A & ~B;
endmodule

module \$_XOR_ (A, B, Y);
input A, B; output Y;
specify (A => Y) = (0,0); (B => Y) = (0,0); endspecify
xor g (Y, A, B);
endmodule

module \$_XNOR_ (A, B, Y);
input A, B; output Y;
specify (A => Y) = (0,0); (B => Y) = (0,0); endspecify
xnor g (Y, A, B);
endmodule

// 上升沿触发、使能、异步低电平复位（复位值 0）的 D 触发器。
// 内部 reg 经连续赋值驱动输出端口 Q，使 C->Q 成为 SDF 可标注的模块路径。
module \$_DFFE_PN0P_ (D, C, E, Q, R);
input D, C, E, R; output Q;
reg qi;
specify
  (posedge C => (Q+:D)) = (0,0);
  (negedge R => (Q-:0)) = (0);
endspecify
assign Q = qi;
always @(posedge C or negedge R)
  if (!R) qi <= 1'b0;
  else if (E) qi <= D;
endmodule
