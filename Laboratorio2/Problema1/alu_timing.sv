`timescale 1ns/1ps
import alu_pkg::*;

module alu_timing #(parameter N = 4) (
    input  logic        clk,
    input  logic        rst,
    input  logic [N-1:0] A_in,
    input  logic [N-1:0] B_in,
    input  op_t          op,
    output logic [N-1:0] Y_out
);
    logic [N-1:0] A_reg, B_reg;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            A_reg <= '0;
            B_reg <= '0;
        end else begin
            A_reg <= A_in;
            B_reg <= B_in;
        end
    end

    logic [N-1:0] Y;
    logic Nf, Zf, Cf, Vf;

    alu #(.N(N)) DUT (.A(A_reg), .B(B_reg), .op(op), .Y(Y), .Nf(Nf), .Zf(Zf), .Cf(Cf), .Vf(Vf));

    always_ff @(posedge clk or posedge rst) begin
        if (rst) Y_out <= '0;
        else     Y_out <= Y;
    end
endmodule
