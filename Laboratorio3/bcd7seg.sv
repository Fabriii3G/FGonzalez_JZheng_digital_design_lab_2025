// bcd7seg.sv — decodifica 0..9 a segmentos con polaridad y mapeo configurables
module bcd7seg #(
  parameter bit ACTIVE_LOW = 1,  // 1: segmentos activos en 0

  // Mapeo: qué segmento lógico (a..g) va a cada bit físico seg[k]
  // Convención interna: a2g[6:0] = {a,b,c,d,e,f,g}
  // Por defecto: seg[0]=a, seg[1]=b, ..., seg[6]=g  (ajusta si tu placa usa otro orden)
  parameter int unsigned M0 = 6, // seg[0] <- a2g[M0]
  parameter int unsigned M1 = 5, // seg[1] <- a2g[M1]
  parameter int unsigned M2 = 4, // seg[2] <- a2g[M2]
  parameter int unsigned M3 = 3, // seg[3] <- a2g[M3]
  parameter int unsigned M4 = 2, // seg[4] <- a2g[M4]
  parameter int unsigned M5 = 1, // seg[5] <- a2g[M5]
  parameter int unsigned M6 = 0  // seg[6] <- a2g[M6]
)(
  input  logic [3:0] bcd,
  output logic [6:0] seg   // bits físicos seg[0]..seg[6] según tu pinout
);
  // a2g_activo1: orden lógico {a,b,c,d,e,f,g}, 1 = segmento encendido
  logic [6:0] a2g_activo1;

  always_comb begin
    unique case (bcd)
      4'd0: a2g_activo1 = 7'b1111110; // a b c d e f on, g off
      4'd1: a2g_activo1 = 7'b0110000; // b c
      4'd2: a2g_activo1 = 7'b1101101; // a b d e g
      4'd3: a2g_activo1 = 7'b1111001; // a b c d g
      4'd4: a2g_activo1 = 7'b0110011; // b c f g
      4'd5: a2g_activo1 = 7'b1011011; // a c d f g
      4'd6: a2g_activo1 = 7'b1011111; // a c d e f g
      4'd7: a2g_activo1 = 7'b1110000; // a b c
      4'd8: a2g_activo1 = 7'b1111111; // a b c d e f g
      4'd9: a2g_activo1 = 7'b1111011; // a b c d f g
      default: a2g_activo1 = 7'b0000001; // guion (solo g) en activo-1
    endcase
  end

  // Reordenar al bus físico seg[0..6] según M0..M6
  logic [6:0] phys_activo1;
  always_comb begin
    phys_activo1[0] = a2g_activo1[M0];
    phys_activo1[1] = a2g_activo1[M1];
    phys_activo1[2] = a2g_activo1[M2];
    phys_activo1[3] = a2g_activo1[M3];
    phys_activo1[4] = a2g_activo1[M4];
    phys_activo1[5] = a2g_activo1[M5];
    phys_activo1[6] = a2g_activo1[M6];
  end

  // Aplicar polaridad de salida
  always_comb begin
    seg = (ACTIVE_LOW) ? ~phys_activo1 : phys_activo1;
  end
endmodule
