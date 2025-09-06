`timescale 1ns/1ps
import alu_pkg::*;

module tb_alu;
  localparam int N = 4;

  logic [N-1:0] A, B;
  op_t          OP;
  logic [N-1:0] Y;     // resultado truncado a 4 bits
  logic Nf, Zf, Cf, Vf;

  // ALU: MUL es UNSIGNED; ADD/SUB/DIV/MOD con signo si SIGNED_OPS=1
  alu #(.N(N), .SIGNED_OPS(1)) DUT (
    .A(A), .B(B), .op(OP),
    .Y(Y), .Nf(Nf), .Zf(Zf), .Cf(Cf), .Vf(Vf)
  );

  task show(string tag);
    // OJO: Quartus no soporta OP.name(), imprimimos el valor numérico del enum
    $display("%s  A=%b  B=%b  OP=%0d  |  Y=%b  {N,Z,C,V}={%0d,%0d,%0d,%0d}",
             tag, A, B, int'(OP), Y, Nf, Zf, Cf, Vf);
  endtask

  initial begin
    $display("=== TB ALU N=%0d (Y truncado a 4 bits; MUL unsigned) ===", N);

    // ---------- ADD ----------
    A=4'd3;  B=4'd5;  OP=OP_ADD; #1; show("ADD 3+5   ");
    A=4'd9;  B=4'd9;  OP=OP_ADD; #1; show("ADD 9+9   ");

    // ---------- SUB ----------
    A=4'd7;  B=4'd2;  OP=OP_SUB; #1; show("SUB 7-2   ");
    A=4'd2;  B=4'd7;  OP=OP_SUB; #1; show("SUB 2-7   ");

    // ---------- MUL (UNSIGNED) ----------
    A=4'b0011; B=4'b0101; OP=OP_MUL; #1; show("MUL 3*5  ");
    A=4'b1111; B=4'b1111; OP=OP_MUL; #1; show("MUL 15*15");

    // ---------- DIV / MOD ----------
    A=4'd9;  B=4'd3;  OP=OP_DIV; #1; show("DIV 9/3   ");
    A=4'd7;  B=4'd2;  OP=OP_DIV; #1; show("DIV 7/2   ");
    A=4'd7;  B=4'd3;  OP=OP_MOD; #1; show("MOD 7%3   ");
    A=4'd9;  B=4'd4;  OP=OP_MOD; #1; show("MOD 9%4   ");

    // ---------- Lógicas ----------
    A=4'hA;  B=4'h5;  OP=OP_AND; #1; show("AND A&B   ");
    A=4'hA;  B=4'h5;  OP=OP_OR;  #1; show("OR  A|B   ");
    A=4'hA;  B=4'h5;  OP=OP_XOR; #1; show("XOR A^B   ");

    // ---------- Shifts ----------
    A=4'b0011; B='0; OP=OP_SLL; #1; show("SLL 0011<<1");
    A=4'b1001; B='0; OP=OP_SLL; #1; show("SLL 1001<<1");
    A=4'b1000; B='0; OP=OP_SRL; #1; show("SRL 1000>>1");
    A=4'b0001; B='0; OP=OP_SRL; #1; show("SRL 0001>>1");

    $display("=== FIN TB ===");
    $finish;
  end
endmodule
