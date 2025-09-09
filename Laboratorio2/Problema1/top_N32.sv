// top_N32.sv
import alu_pkg::*;
module top_N32 (
  input  logic         clk,
  input  logic         rst,
  input  logic [31:0]  A,
  input  logic [31:0]  B,
  input  op_t          op,
  output logic [31:0]  Y
);
  alu_timing #(.N(32)) u (
    .clk(clk), .rst(rst),
    .A_in(A), .B_in(B),
    .op(op),
    .Y_out(Y)
  );
endmodule
