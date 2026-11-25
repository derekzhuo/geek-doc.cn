set architecture riscv:rv64
target remote 127.0.0.1:1234
break *0x80000000
