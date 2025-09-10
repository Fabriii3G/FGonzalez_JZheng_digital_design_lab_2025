`timescale 1ns/1ps
import alu_pkg::*;

module tb_alu;
  localparam int N = 4;
  localparam bit SIGNED_OPS = 1'b1;   

  // DUT
  logic [N-1:0] A, B;
  op_t          OP;
  logic [N-1:0] Y;
  logic Nf, Zf, Cf, Vf;

  alu #(.N(N), .SIGNED_OPS(SIGNED_OPS)) DUT (
    .A(A), .B(B), .op(OP),
    .Y(Y), .Nf(Nf), .Zf(Zf), .Cf(Cf), .Vf(Vf)
  );

  // ---------- Utilidades ----------
  function automatic string op2s(op_t x);
    case (x)
      OP_ADD: op2s = "ADD";
      OP_SUB: op2s = "SUB";
      OP_MUL: op2s = "MUL";
      OP_DIV: op2s = "DIV";
      OP_MOD: op2s = "MOD";
      OP_AND: op2s = "AND";
      OP_OR : op2s = "OR";
      OP_XOR: op2s = "XOR";
      OP_SLL: op2s = "SLL";
      OP_SRL: op2s = "SRL";
      default: op2s = "UNK";
    endcase
  endfunction

  // Modelo de referencia: calcula lo que *debería* salir (Y,N,Z,C,V)
  task automatic ref_eval(
    input  op_t          opi,
    input  logic [N-1:0] ai, bi,
    output logic [N-1:0] eY,
    output logic         eN, eZ, eC, eV
  );
    logic [N:0]     sum_u, diff_u;
    logic [2*N-1:0] wide;
    logic [N-1:0]   sh;

    eY='0; eN=1'b0; eZ=1'b0; eC=1'b0; eV=1'b0;
    sum_u='0; diff_u='0; wide='0; sh='0;

    unique case (opi)
      OP_ADD: begin
        sum_u = {1'b0, ai} + {1'b0, bi};
        eY    = sum_u[N-1:0];
        eC    = sum_u[N];
        eV    = SIGNED_OPS ? ((ai[N-1]==bi[N-1]) && (eY[N-1]!=ai[N-1])) : eC;
      end
      OP_SUB: begin
        diff_u = {1'b0, ai} + {1'b0, ~bi} + 1'b1;
        eY     = diff_u[N-1:0];
        eC     = diff_u[N];
        eV     = SIGNED_OPS ? ((ai[N-1]!=bi[N-1]) && (eY[N-1]!=ai[N-1])) : ~eC;
      end
      OP_MUL: begin
        wide = {{N{1'b0}}, ai} * {{N{1'b0}}, bi}; 
        eY   = wide[N-1:0];
        eV   = |wide[2*N-1:N];
        eC   = eV; 
      end
      OP_DIV: begin
        if (bi=='0) begin
          eY='0; eC=1'b0; eV=1'b1;
        end else begin
          eY = ai / bi; 
          eC=1'b0; eV=1'b0;
        end
      end
      OP_MOD: begin
        if (bi=='0) begin
          eY='0; eC=1'b0; eV=1'b1;
        end else begin
          eY = ai % bi; 
          eC=1'b0; eV=1'b0;
        end
      end
      OP_AND: begin eY = ai & bi; eC=1'b0; eV=1'b0; end
      OP_OR : begin eY = ai | bi; eC=1'b0; eV=1'b0; end
      OP_XOR: begin eY = ai ^ bi; eC=1'b0; eV=1'b0; end
      OP_SLL: begin
        sh = (ai << 1);
        eY = sh;
        eC = ai[N-1];
        eV = SIGNED_OPS ? (eY[N-1] != ai[N-1]) : 1'b0;
      end
      OP_SRL: begin
        sh = (ai >> 1);
        eY = sh;
        eC = ai[0];
        eV = 1'b0;
      end
      default: begin eY='0; eC=1'b0; eV=1'b0; end
    endcase

    // Flags finales
    eZ = (eY == '0);
    eN = (SIGNED_OPS && (opi==OP_ADD || opi==OP_SUB || opi==OP_SLL)) ? eY[N-1] : 1'b0;
  endtask

  // Aplica estímulos, espera, calcula referencia y hace asserts
  int fails = 0;
  task automatic apply_and_check(input string name, input op_t opi, input logic [N-1:0] ai, bi);
    logic [N-1:0] eY; logic eN,eZ,eC,eV;
    A = ai; B = bi; OP = opi; #1;
    ref_eval(opi, ai, bi, eY, eN, eZ, eC, eV);

    // Y
    assert (Y === eY)
      else begin
        $error("[Y] %s OP=%s A=%b B=%b  got=%b exp=%b", name, op2s(opi), A, B, Y, eY);
        fails++;
      end
    // N Z C V
    assert (Nf === eN)
      else begin
        $error("[N] %s OP=%s A=%b B=%b  got=%0b exp=%0b", name, op2s(opi), A, B, Nf, eN);
        fails++;
      end
    assert (Zf === eZ)
      else begin
        $error("[Z] %s OP=%s A=%b B=%b  got=%0b exp=%0b", name, op2s(opi), A, B, Zf, eZ);
        fails++;
      end
    assert (Cf === eC)
      else begin
        $error("[C] %s OP=%s A=%b B=%b  got=%0b exp=%0b", name, op2s(opi), A, B, Cf, eC);
        fails++;
      end
    assert (Vf === eV)
      else begin
        $error("[V] %s OP=%s A=%b B=%b  got=%0b exp=%0b", name, op2s(opi), A, B, Vf, eV);
        fails++;
      end
  endtask

  // ---------- Tests ----------
  initial begin
    $display("=== TB ALU N=%0d (self-check con asserts) ===", N);

    // ADD
    apply_and_check("ADD 3+5   ", OP_ADD, 4'd3,  4'd5);
    apply_and_check("ADD 9+9   ", OP_ADD, 4'd9,  4'd9);

    // SUB
    apply_and_check("SUB 7-2   ", OP_SUB, 4'd7,  4'd2);
    apply_and_check("SUB 2-7   ", OP_SUB, 4'd2,  4'd7);

    // MUL 
    apply_and_check("MUL 3*5   ", OP_MUL, 4'b0011, 4'b0101);
    apply_and_check("MUL 15*15 ", OP_MUL, 4'b1111, 4'b1111);

    // DIV / MOD 
    apply_and_check("DIV 9/3   ", OP_DIV, 4'd9,  4'd3);
    apply_and_check("DIV 7/2   ", OP_DIV, 4'd7,  4'd2);
    apply_and_check("MOD 7%3   ", OP_MOD, 4'd7,  4'd3);
    apply_and_check("MOD 9%4   ", OP_MOD, 4'd9,  4'd4);

    // Lógicas
    apply_and_check("AND A&B   ", OP_AND, 4'hA,  4'h5);
    apply_and_check("OR  A|B   ", OP_OR , 4'hA,  4'h5);
    apply_and_check("XOR A^B   ", OP_XOR, 4'hA,  4'h5);

    // Shifts
    apply_and_check("SLL 0011<<1", OP_SLL, 4'b0011, '0);
    apply_and_check("SLL 1001<<1", OP_SLL, 4'b1001, '0);
    apply_and_check("SRL 1000>>1", OP_SRL, 4'b1000, '0);
    apply_and_check("SRL 0001>>1", OP_SRL, 4'b0001, '0);

    // Casos de error esperados (divide/mod por cero)
    apply_and_check("DIV x/0   ", OP_DIV, 4'd9,  4'd0);
    apply_and_check("MOD x/0   ", OP_MOD, 4'd9,  4'd0);

    if (fails==0) begin
      $display("=== TODO OK: %0d tests, 0 fails ===", 18);
    end else begin
      $fatal(1, "=== FALLAS: %0d ===", fails);
    end
    $finish;
  end
endmodule
