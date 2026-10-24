# Register map: demo peripheral

| name      | offset | width | access | reset | description          |
|-----------|--------|-------|--------|-------|----------------------|
| CTRL      | 0x00   | 32    | RW     | 0x0   | global control       |
| STATUS    | 0x04   | 32    | RO     | 0x0   | status flags         |
| BAUD_DIV  | 0x08   | 16    | RW     | 0x1B  | baud rate divider    |
| IRQ_MASK  | 0x0C   | 8     | RW     | 0x00  | interrupt mask       |
| FIFO_DATA | 0x10   | 8     | RW     | 0x00  | FIFO data port       |
