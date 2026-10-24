// Minimal module consuming the auto-generated regs.vh to prove it compiles.
`include "regs.vh"
module reg_user (
    input  wire [31:0] addr,
    output reg         hit
);
    always @(*) begin
        case (addr & `REG_CTRL_MASK)          // mask check is nonsense-ish but legal
            `REG_CTRL_ADDR:      hit = 1'b1;
            `REG_STATUS_ADDR:    hit = 1'b1;
            `REG_BAUD_DIV_ADDR:  hit = 1'b1;
            `REG_IRQ_MASK_ADDR:  hit = 1'b1;
            `REG_FIFO_DATA_ADDR: hit = 1'b1;
            default:             hit = 1'b0;
        endcase
    end
endmodule
