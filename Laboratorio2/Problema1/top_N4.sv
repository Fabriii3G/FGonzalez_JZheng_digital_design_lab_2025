// top_N4.sv
import alu_pkg::*;
module top_N4 (
  input  logic        clk,
  input  logic        rst,
  input  logic [3:0]  A,
  input  logic [3:0]  B,
  input  op_t         op,
  output logic [3:0]  Y
);
  alu_timing #(.N(4)) u (
    .clk(clk), .rst(rst),
    .A_in(A), .B_in(B),
    .op(op),
    .Y_out(Y)
  );
endmodule
