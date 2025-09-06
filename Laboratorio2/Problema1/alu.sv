import alu_pkg::*;

module alu #(
  parameter int N = 4,
  // Si =1, ADD/SUB usan aritmética con signo (2's complement).
  // MUL, DIV y MOD se fuerzan a UNSIGNED (como pediste).
  parameter bit SIGNED_OPS = 1'b1
)(
  input  logic [N-1:0] A, B,
  input  op_t          op,
  output logic [N-1:0] Y,      // resultado truncado a N bits (LSB)
  output logic         Nf, Zf, Cf, Vf
);

  // Temporales (sin inicializar en la declaración)
  logic [N-1:0]   yN;
  logic           cf, vf;
  logic [2*N-1:0] wide;
  logic [N:0]     sum_u, diff_u;
  logic [N-1:0]   sh_tmp;

  always_comb begin
    // Defaults
    yN     = '0;
    cf     = 1'b0;
    vf     = 1'b0;
    wide   = '0;
    sum_u  = '0;
    diff_u = '0;
    sh_tmp = '0;

    unique case (op)
      // ===================== ADD =====================
      OP_ADD: begin
        sum_u = {1'b0, A} + {1'b0, B};
        yN    = sum_u[N-1:0];            // truncado a N bits
        cf    = sum_u[N];                // carry-out (unsigned)
        if (SIGNED_OPS)  vf = (A[N-1]==B[N-1]) && (yN[N-1]!=A[N-1]); // overflow con signo
        else             vf = cf;        // overflow unsigned ≡ carry
      end

      // ===================== SUB (A - B) =====================
      OP_SUB: begin
        // A + (~B + 1)
        diff_u = {1'b0, A} + {1'b0, ~B} + 1'b1;
        yN     = diff_u[N-1:0];
        cf     = diff_u[N];  // 1 = no borrow, 0 = borrow
        if (SIGNED_OPS)  vf = (A[N-1]!=B[N-1]) && (yN[N-1]!=A[N-1]);
        else             vf = ~cf;       // opcional: reportar borrow como overflow en unsigned
      end

      // ===================== MUL (SIEMPRE UNSIGNED) =====================
      OP_MUL: begin
        wide = {{N{1'b0}}, A} * {{N{1'b0}}, B}; // UNSIGNED
        yN   = wide[N-1:0];                     // truncado a N bits (LSB)
        vf   = |wide[2*N-1:N];                  // overflow si hubo bits altos
        cf   = vf;                              // opcional: reflejar overflow en CF
      end

      // ===================== DIV (SIEMPRE UNSIGNED) =====================
      OP_DIV: begin
        if (B == '0) begin
          yN='0; cf=1'b0; vf=1'b1;             // división por cero
        end else begin
          yN = A / B;                           // cociente 0..(2^N-1)
          cf = 1'b0; vf = 1'b0;
        end
      end

      // ===================== MOD (SIEMPRE UNSIGNED) =====================
      OP_MOD: begin
        if (B == '0) begin
          yN='0; cf=1'b0; vf=1'b1;             // módulo por cero
        end else begin
          yN = A % B;                           // resto 0..B-1
          cf = 1'b0; vf = 1'b0;
        end
      end

      // ===================== Lógicas =====================
      OP_AND: begin yN = A & B; cf=1'b0; vf=1'b0; end
      OP_OR : begin yN = A | B; cf=1'b0; vf=1'b0; end
      OP_XOR: begin yN = A ^ B; cf=1'b0; vf=1'b0; end

      // ===================== Shifts =====================
      // Nota: desplazo 1 bit. Si quieres usar B como cantidad, cambia <<1 / >>1 por <<B / >>B.
      OP_SLL: begin
        sh_tmp = (A << 1);
        yN = sh_tmp;
        cf = A[N-1];                          // bit expulsado
        vf = SIGNED_OPS ? (yN[N-1]!=A[N-1]) : 1'b0; // cambio de signo = overflow (si con signo)
      end
      OP_SRL: begin
        sh_tmp = (A >> 1);
        yN = sh_tmp;
        cf = A[0];                             // bit expulsado
        vf = 1'b0;
      end

      default: begin
        yN='0; cf=1'b0; vf=1'b0;
      end
    endcase
  end

  // Salidas finales
  assign Y  = yN;              // siempre N bits (truncado)
  assign Zf = (yN == '0);
  assign Nf = (SIGNED_OPS && (op==OP_ADD || op==OP_SUB || op==OP_SLL)) ? yN[N-1] : 1'b0;
  assign Cf = cf;
  assign Vf = vf;

endmodule
