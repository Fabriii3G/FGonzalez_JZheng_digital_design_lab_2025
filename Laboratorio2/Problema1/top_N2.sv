// top_N2.sv
import alu_pkg::*;
module top_N2 (
  input  logic        clk,
  input  logic        rst,
  input  logic [1:0]  A,
  input  logic [1:0]  B,
  input  op_t         op,
  output logic [1:0]  Y
);
  alu_timing #(.N(2)) u (
    .clk(clk), .rst(rst),
    .A_in(A), .B_in(B),
    .op(op),
    .Y_out(Y)
  );
endmodule
