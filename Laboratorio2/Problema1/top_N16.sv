import alu_pkg::*;
module top_N16 (
  input  logic         clk,
  input  logic         rst,
  input  logic [15:0]  A,
  input  logic [15:0]  B,
  input  op_t          op,
  output logic [15:0]  Y
);
  alu_timing #(.N(16)) u (
    .clk(clk), .rst(rst),
    .A_in(A), .B_in(B),
    .op(op),
    .Y_out(Y)
  );
endmodule
