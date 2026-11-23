`timescale 1ns/1ps
// 8N1 UART transmitter: 1 start bit (0), 8 data bits LSB first,
// 1 stop bit (1). One bit time lasts CLKS_PER_BIT input clocks, so
// baud = f_clk / CLKS_PER_BIT. A one-cycle pulse on `start` launches
// one frame; `done` pulses when the stop bit completes.
module uart_tx #(
  parameter CLKS_PER_BIT = 8
) (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       start,
  input  wire [7:0] tx_byte,
  output reg        tx,
  output reg        done
);
  localparam IDLE  = 2'd0;
  localparam START = 2'd1;
  localparam DATA  = 2'd2;
  localparam STOP  = 2'd3;

  localparam CW = $clog2(CLKS_PER_BIT);

  reg [1:0]            state;
  reg [CW-1:0]         c;
  reg [2:0]            bit_idx;
  reg [7:0]            buf_byte;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= IDLE;
      tx       <= 1'b1;
      done     <= 1'b0;
      c        <= {CW{1'b0}};
      bit_idx  <= 3'd0;
      buf_byte <= 8'd0;
    end else begin
      done <= 1'b0;
      case (state)
        IDLE: begin
          tx <= 1'b1;
          if (start) begin
            buf_byte <= tx_byte;
            state    <= START;
            c        <= {CW{1'b0}};
            bit_idx  <= 3'd0;
          end
        end

        START: begin
          tx <= 1'b0;
          if (c == CLKS_PER_BIT - 1) begin
            c     <= {CW{1'b0}};
            state <= DATA;
          end else begin
            c <= c + 1'b1;
          end
        end

        DATA: begin
          tx <= buf_byte[bit_idx];
          if (c == CLKS_PER_BIT - 1) begin
            c <= {CW{1'b0}};
            if (bit_idx == 3'd7) begin
              bit_idx <= 3'd0;
              state   <= STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            c <= c + 1'b1;
          end
        end

        STOP: begin
          tx <= 1'b1;
          if (c == CLKS_PER_BIT - 1) begin
            c     <= {CW{1'b0}};
            state <= IDLE;
            done  <= 1'b1;
          end else begin
            c <= c + 1'b1;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end
endmodule