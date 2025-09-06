// ======================================================
// Top para FPGA: ALU N=4 con switches y botón que cicla ops
// - SW[7:4] = A, SW[3:0] = B
// - KEY[0]  = botón (activo en bajo) para avanzar operación
// - HEX2    = índice de operación (siempre visible, 0..9)
// - HEX1:HEX0 = resultado Y (8 bits) en HEX
// - LEDR[3:0] = {Vf,Cf,Zf,Nf}; resto de LEDs en 0
// ======================================================
`timescale 1ns/1ps
import alu_pkg::*;

module top_alu_fpga #(
  parameter int N = 4,
  parameter int F_CLK_HZ = 50_000_000,
  parameter bit ACTIVE_LOW_BTNS = 1,   // KEY activos en bajo en placas Intel
  parameter bit ACTIVE_LOW_7SEG = 1    // HEX activos en bajo en placas Intel
)(
  input  logic        CLOCK_50,
  input  logic [7:0]  SW,          // SW[7:4]=A, SW[3:0]=B
  input  logic [3:0]  KEY,         // usar KEY[0]
  output logic [6:0]  HEX0,        // gfedcba
  output logic [6:0]  HEX1,        // gfedcba
  output logic [6:0]  HEX2,        // gfedcba (índice de operación)
  output logic [9:0]  LEDR
);

  // ---------- Entradas ----------
  wire btn_raw;
  assign btn_raw = (ACTIVE_LOW_BTNS) ? ~KEY[0] : KEY[0]; // botón activo en alto

  wire [N-1:0] A;
  wire [N-1:0] B;
  assign A = SW[7:4];
  assign B = SW[3:0];

  // ---------- Debounce + pulso único ----------
  logic btn_deb, btn_pulse;
  debounce #(.F_CLK_HZ(F_CLK_HZ), .MS(15)) u_db (.clk(CLOCK_50), .din(btn_raw), .dout(btn_deb));
  one_pulse u_pulse (.clk(CLOCK_50), .din(btn_deb), .pulse(btn_pulse));

  // ---------- Selector de operación (cíclico) ----------
  // Mapa: 0=ADD,1=SUB,2=MUL,3=DIV,4=MOD,5=AND,6=OR,7=XOR,8=SLL,9=SRL
  logic [3:0] op_idx = 4'd0;
  always_ff @(posedge CLOCK_50) begin
    if (btn_pulse) begin
      op_idx <= (op_idx == 4'd9) ? 4'd0 : op_idx + 4'd1;
    end
  end

  op_t OP;
  always_comb begin
    unique case (op_idx)
      4'd0: OP = OP_ADD;
      4'd1: OP = OP_SUB;
      4'd2: OP = OP_MUL;
      4'd3: OP = OP_DIV;
      4'd4: OP = OP_MOD;
      4'd5: OP = OP_AND;
      4'd6: OP = OP_OR;
      4'd7: OP = OP_XOR;
      4'd8: OP = OP_SLL;
      4'd9: OP = OP_SRL;
      default: OP = OP_ADD;
    endcase
  end

  // ---------- ALU ----------
  logic [2*N-1:0] Y;
  logic Nf, Zf, Cf, Vf;

  alu #(.N(N)) U_ALU (
    .A(A), .B(B), .op(OP),
    .Y(Y), .Nf(Nf), .Zf(Zf), .Cf(Cf), .Vf(Vf)
  );

  // ---------- Displays ----------
  // Resultado en HEX (dos nibbles)
  logic [6:0] seg0_res, seg1_res;
  hex7seg u_hex0_res (.val(Y[3:0]),       .seg(seg0_res));
  hex7seg u_hex1_res (.val(Y[2*N-1:N]),   .seg(seg1_res));

  // Índice de operación (0..9) fijo en HEX2
  logic [6:0] seg2_idx;
  hex7seg u_hex2_idx (.val(op_idx[3:0]),  .seg(seg2_idx));

  // Ajuste de polaridad (activo en bajo típico Intel)
  assign HEX0 = (ACTIVE_LOW_7SEG) ? seg0_res : ~seg0_res;
  assign HEX1 = (ACTIVE_LOW_7SEG) ? seg1_res : ~seg1_res;
  assign HEX2 = (ACTIVE_LOW_7SEG) ? seg2_idx : ~seg2_idx;

  // ---------- LEDs de apoyo ----------
  assign LEDR[3:0] = {Vf, Cf, Zf, Nf}; // flags
  assign LEDR[9:4] = 6'b0;             // sin uso

endmodule

// ======================================================
// Debouncer simple (retarda MS milisegundos)
// ======================================================
module debounce #(
  parameter int F_CLK_HZ = 50_000_000,
  parameter int MS       = 15
)(
  input  logic clk,
  input  logic din,     // activo en alto
  output logic dout
);
  localparam int CNT_MAX = (F_CLK_HZ/1000) * MS;
  logic [$clog2(CNT_MAX+1)-1:0] cnt;
  logic state;

  always_ff @(posedge clk) begin
    if (din != state) begin
      if (cnt == CNT_MAX[$clog2(CNT_MAX+1)-1:0]) begin
        state <= din;
        cnt   <= '0;
      end else begin
        cnt <= cnt + 1'b1;
      end
    end else begin
      cnt <= '0;
    end
  end

  assign dout = state;
endmodule

// ======================================================
// Generador de pulso 1 ciclo en flanco de subida
// ======================================================
module one_pulse(
  input  logic clk,
  input  logic din,
  output logic pulse
);
  logic dly;
  always_ff @(posedge clk) begin
    dly   <= din;
    pulse <= din & ~dly;
  end
endmodule

// ======================================================
// Decodificador HEX → 7 segmentos (gfedcba, activo en bajo)
// ======================================================
module hex7seg(
  input  logic [3:0] val,
  output logic [6:0] seg   // g f e d c b a
);
  always_comb begin
    unique case (val)
      4'h0: seg = 7'b1000000;
      4'h1: seg = 7'b1111001;
      4'h2: seg = 7'b0100100;
      4'h3: seg = 7'b0110000;
      4'h4: seg = 7'b0011001;
      4'h5: seg = 7'b0010010;
      4'h6: seg = 7'b0000010;
      4'h7: seg = 7'b1111000;
      4'h8: seg = 7'b0000000;
      4'h9: seg = 7'b0010000;
      4'hA: seg = 7'b0001000;
      4'hB: seg = 7'b0000011;
      4'hC: seg = 7'b1000110;
      4'hD: seg = 7'b0100001;
      4'hE: seg = 7'b0000110;
      4'hF: seg = 7'b0001110;
      default: seg = 7'b1111111; // apagado
    endcase
  end
endmodule
