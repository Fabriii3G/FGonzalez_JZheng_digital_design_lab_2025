// -----------------------------------------------------------------------------
// sevseg_mux2.sv — Multiplexor para 2 displays de 7 segmentos (comparten {a..g})
// - Refrescado ~1 kHz por dígito desde clk de 50 MHz (parametrizable)
// - Polaridad de segmentos y de dígitos parametrizable
// -----------------------------------------------------------------------------
module sevseg_mux2 #(
  parameter int CLK_HZ          = 50_000_000,
  parameter int REFRESH_HZ      = 1000,   // ~1 kHz por dígito (2 kHz conmutación total)
  parameter bit SEG_ACTIVE_LOW  = 1,      // 1: segmentos activos en 0
  parameter bit DIG_ACTIVE_LOW  = 1       // 1: habilitación de dígito en 0
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic [3:0]  bcd_tens,
  input  logic [3:0]  bcd_ones,
  output logic [6:0]  seg_o,   // bus compartido {a,b,c,d,e,f,g}
  output logic [1:0]  dig_o    // [0]=unidades, [1]=decenas
);

  // 1) Decodificar ambos dígitos
  logic [6:0] seg_tens, seg_ones;
  bcd7seg #(.ACTIVE_LOW(SEG_ACTIVE_LOW)) u7a (.bcd(bcd_tens), .seg(seg_tens));
  bcd7seg #(.ACTIVE_LOW(SEG_ACTIVE_LOW)) u7b (.bcd(bcd_ones), .seg(seg_ones));

  // 2) Divisor para alternar dígito a 2*REFRESH_HZ
  localparam int TOGGLE_HZ   = REFRESH_HZ * 2;
  localparam int DIV         = (TOGGLE_HZ > 0) ? (CLK_HZ / TOGGLE_HZ) : 1;
  localparam int CNT_BITS    = (DIV <= 1) ? 1 : $clog2(DIV);

  logic [CNT_BITS-1:0] divcnt;
  logic sel;  // 0: unidades, 1: decenas

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      divcnt <= '0;
      sel    <= 1'b0;
    end else begin
      if (divcnt == DIV-1) begin
        divcnt <= '0;
        sel    <= ~sel;
      end else begin
        divcnt <= divcnt + 1'b1;
      end
    end
  end

  // 3) Multiplexar segmentos y habilitaciones (sin declarar señales dentro)
  logic [1:0] dig_en;

  always_comb begin
    // Patrón de segmentos según dígito seleccionado
    seg_o = (sel == 1'b0) ? seg_ones : seg_tens;

    // Habilitación de dígitos según polaridad
    if (DIG_ACTIVE_LOW) begin
      // Activo en 0: dig_o=01 -> unidades ON, 10 -> decenas ON
      dig_en = (sel == 1'b0) ? 2'b10 : 2'b01; // antes de invertir
      dig_o  = ~dig_en;
    end else begin
      // Activo en 1
      dig_en = (sel == 1'b0) ? 2'b01 : 2'b10;
      dig_o  = dig_en;
    end

    // (Opcional) Forzar apagado total si quieres un estado de fallo:
    // if (/*condición*/) seg_o = (SEG_ACTIVE_LOW) ? 7'h7F : 7'h00;
  end

endmodule
