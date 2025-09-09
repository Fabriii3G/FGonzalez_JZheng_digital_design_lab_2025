// top_N8.sv
import alu_pkg::*;
module top_N8 (
  input  logic        clk,
  input  logic        rst,
  input  logic [7:0]  A,
  input  logic [7:0]  B,
  input  op_t         op,
  output logic [7:0]  Y
);
  alu_timing #(.N(8)) u (
    .clk(clk), .rst(rst),
    .A_in(A), .B_in(B),
    .op(op),
    .Y_out(Y)
  );
endmodule
