`timescale 1ns/1ps
import alu_pkg::*;


module tb_alu;
  import alu_pkg::*;

  localparam int N = 4;

  logic [N-1:0] A, B;
  op_t          OP;
  logic [2*N-1:0] Y;
  logic Nf, Zf, Cf, Vf;

  alu #(.N(N)) DUT (
    .A(A), .B(B), .op(OP),
    .Y(Y), .Nf(Nf), .Zf(Zf), .Cf(Cf), .Vf(Vf)
  );

  // Tarea de check
  task check(input string name, input logic [2*N-1:0] got, input logic [2*N-1:0] exp);
    if (got !== exp) begin
      $display("[FAIL] %s: got=%0h exp=%0h  A=%0h B=%0h OP=%0h", name, got, exp, A, B, OP);
    end else begin
      $display("[ OK ] %s: %0h == %0h", name, got, exp);
    end
  endtask

  initial begin
    $display("=== TB ALU N=%0d ===", N);

    // -------- ADD (2 casos) --------
    OP = OP_ADD;
    // Caso 1: 3 + 5 = 8
    A = 4'd3; B = 4'd5; #1;
    check("ADD 3+5", Y, { {N{1'b0}}, 4'd8 });

    // Caso 2: 9 + 9 = 18 (0x12) -> sum N=4 -> 2, cout=1
    A = 4'd9; B = 4'd9; #1;
    check("ADD 9+9", Y, { {N{1'b0}}, (4'd9 + 4'd9) }); // esperado 0x12 -> Y=0x02 extendido

    // -------- SUB (2 casos) --------
    OP = OP_SUB;
    // Caso 1: 7 - 2 = 5
    A = 4'd7; B = 4'd2; #1;
    check("SUB 7-2", Y, { {N{1'b0}}, 4'd5 });

    // Caso 2: 2 - 7 = (wrap 4b) => 2-7 = -5 -> 4b = 11 (0xB)
    A = 4'd2; B = 4'd7; #1;
    check("SUB 2-7", Y, { {N{1'b0}}, (4'(2)-4'(7)) }); // esperado 0xB

    // -------- MUL (2 casos) --------
    OP = OP_MUL;
    // Caso 1: 3 * 5 = 15 (0x0F)
    A = 4'd3; B = 4'd5; #1;
    check("MUL 3*5", Y, (4'd3 * 4'd5));

    // Caso 2: 15 * 15 = 225 (0x00E1 en 8 bits; en 2N=8 bits)
    A = 4'd15; B = 4'd15; #1;
    check("MUL 15*15", Y, (4'd15 * 4'd15));

    // -------- DIV (2 casos, operador permitido) --------
    OP = OP_DIV;
    A = 4'd9; B = 4'd3; #1;
    check("DIV 9/3", Y, { {N{1'b0}}, 4'd3 });
    A = 4'd7; B = 4'd2; #1;
    check("DIV 7/2", Y, { {N{1'b0}}, 4'd3 });

    // -------- MOD (2 casos) --------
    OP = OP_MOD;
    A = 4'd7; B = 4'd3; #1;
    check("MOD 7%3", Y, { {N{1'b0}}, 4'd1 });
    A = 4'd9; B = 4'd4; #1;
    check("MOD 9%4", Y, { {N{1'b0}}, 4'd1 });

    // -------- AND / OR / XOR (2 casos cada uno) --------
    OP = OP_AND; A=4'hA; B=4'h5; #1; check("AND A(1010)&B(0101)", Y, { {N{1'b0}}, 4'h0});
    OP = OP_AND; A=4'hF; B=4'hC; #1; check("AND F&C", Y, { {N{1'b0}}, 4'hC});

    OP = OP_OR;  A=4'hA; B=4'h5; #1; check("OR  A|B", Y, { {N{1'b0}}, 4'hF});
    OP = OP_OR;  A=4'h0; B=4'hC; #1; check("OR  0|C", Y, { {N{1'b0}}, 4'hC});

    OP = OP_XOR; A=4'hA; B=4'h5; #1; check("XOR A^B", Y, { {N{1'b0}}, 4'hF});
    OP = OP_XOR; A=4'hF; B=4'hF; #1; check("XOR F^F", Y, { {N{1'b0}}, 4'h0});

    // -------- SLL / SRL (2 casos cada uno) --------
    OP = OP_SLL; A=4'b0011; B='0; #1; check("SLL 0011<<1", Y, { {N{1'b0}}, 4'b0110});
    OP = OP_SLL; A=4'b1001; B='0; #1; check("SLL 1001<<1", Y, { {N{1'b0}}, 4'b0010}); // wrap natural de 4b

    OP = OP_SRL; A=4'b1000; B='0; #1; check("SRL 1000>>1", Y, { {N{1'b0}}, 4'b0100});
    OP = OP_SRL; A=4'b0001; B='0; #1; check("SRL 0001>>1", Y, { {N{1'b0}}, 4'b0000});

    $display("=== FIN TB ===");
    $finish;
  end
endmodule
