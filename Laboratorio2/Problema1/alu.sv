import alu_pkg::*;


module alu #(
  parameter int N = 4
)(
  input  logic [N-1:0] A, B,
  input  alu_pkg::op_t op,
  output logic [2*N-1:0] Y,     // salida ancha para MUL
  output logic Nf, Zf, Cf, Vf   // flags: Negativo, Cero, Carry, Overflow
);
  // --- Instancias "modelo 1" ---
  // ADD (RCA)
  logic [N-1:0] add_s;
  logic         add_cout;
  rca_adder #(.N(N)) u_add (
    .a   (A), .b(B), .cin(1'b0),
    .sum (add_s), .cout(add_cout)
  );

  // SUB (Ripple-Borrow)
  logic [N-1:0] sub_d;
  logic         sub_bout;
  ripple_subtractor #(.N(N)) u_sub (
    .a   (A), .b(B), .bin(1'b0),
    .diff(sub_d), .bout(sub_bout)
  );

  // MUL (Array)
  logic [2*N-1:0] mul_p;
  array_multiplier #(.N(N)) u_mul (
    .a (A), .b(B), .p(mul_p)
  );

	  // --- Resto de operaciones (permitido por enunciado)
	logic [N-1:0] div_q;
	logic [N-1:0] mod_r;
	logic [N-1:0] and_r;
	logic [N-1:0] or_r;
	logic [N-1:0] xor_r;
	logic [N-1:0] sll_r;
	logic [N-1:0] srl_r;

	assign div_q = (B != 0) ? (A / B) : '0;
	assign mod_r = (B != 0) ? (A % B) : '0;
	assign and_r = A & B;
	assign or_r  = A | B;
	assign xor_r = A ^ B;
	assign sll_r = A << 1;   // si quieres parametrizar el shift, lo cambiamos luego
	assign srl_r = A >> 1;


  // --- Selección de resultado ---
  logic [N-1:0] yN;   // resultado N-bit "base" (para flags C/V en ADD/SUB)
  always_comb begin
    // default
    Y  = '0;
    yN = '0;

    unique case (op)
      alu_pkg::OP_ADD: begin
        yN = add_s;
        Y  = { {N{1'b0}}, add_s }; // extender a 2N
      end

      alu_pkg::OP_SUB: begin
        yN = sub_d;
        Y  = { {N{1'b0}}, sub_d };
      end

      alu_pkg::OP_MUL: begin
        yN = mul_p[N-1:0]; // para evaluar V con base N si se desea
        Y  = mul_p;
      end

      alu_pkg::OP_DIV: begin
        yN = div_q;
        Y  = { {N{1'b0}}, div_q };
      end

      alu_pkg::OP_MOD: begin
        yN = mod_r;
        Y  = { {N{1'b0}}, mod_r };
      end

      alu_pkg::OP_AND: begin
        yN = and_r;
        Y  = { {N{1'b0}}, and_r };
      end

      alu_pkg::OP_OR: begin
        yN = or_r;
        Y  = { {N{1'b0}}, or_r };
      end

      alu_pkg::OP_XOR: begin
        yN = xor_r;
        Y  = { {N{1'b0}}, xor_r };
      end

      alu_pkg::OP_SLL: begin
        yN = sll_r;
        Y  = { {N{1'b0}}, sll_r };
      end

      alu_pkg::OP_SRL: begin
        yN = srl_r;
        Y  = { {N{1'b0}}, srl_r };
      end

      default: begin
        yN = '0;
        Y  = '0;
      end
    endcase
  end

  // --- Flags ---
  // Z y N sobre la salida ancha Y (como tu "calculadora" de 7-seg)
  assign Zf = (Y == '0);
  assign Nf = Y[2*N-1];

  // C y V relevantes sobre ADD/SUB (N bits). Para otras, definimos criterio simple.
  // Carry (Cf):
  always_comb begin
    unique case (op)
      alu_pkg::OP_ADD: Cf = add_cout;
      // En resta, interpretamos borrow como "no hubo préstamo" => C = ~borrow (estilo 6502),
      // o si prefieres C = borrow, cámbialo aquí.
      alu_pkg::OP_SUB: Cf = sub_bout;
      alu_pkg::OP_SLL: Cf = A[N-1];     // bit que se pierde al desplazar
      alu_pkg::OP_SRL: Cf = A[0];       // bit expulsado
      default:         Cf = 1'b0;
    endcase
  end

  // Overflow (V) solo en suma/resta con signo (N bits)
  // V_add = (~(A[N-1]^B[N-1]) & (A[N-1]^sum[N-1]))
  // V_sub = ( (A[N-1]^B[N-1]) & (A[N-1]^diff[N-1]) )
  always_comb begin
    unique case (op)
      alu_pkg::OP_ADD: Vf = (~(A[N-1]^B[N-1])) & (A[N-1]^yN[N-1]);
      alu_pkg::OP_SUB: Vf = ( (A[N-1]^B[N-1]) ) & (A[N-1]^yN[N-1]);
      default:         Vf = 1'b0;
    endcase
  end

endmodule
