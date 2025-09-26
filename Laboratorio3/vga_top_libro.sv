// vga_top_libro.sv — VGA + cuenta regresiva 15→0 en HEX1..HEX0 (sin multiplex)
// HEX0 = unidades  (seg0_o[6:0])
// HEX1 = decenas   (seg1_o[6:0])

import lab3_params::*;

module vga_top_libro(
  input  logic        clk,
  input  logic        rst_n,
  // VGA
  output logic        hsync,
  output logic        vsync,
  output logic        vga_clk,
  output logic        vga_blank_n,
  output logic        vga_sync_n,
  output logic [7:0]  vga_r,
  output logic [7:0]  vga_g,
  output logic [7:0]  vga_b,

  // 7 segmentos SIN multiplex (un bus por dígito)
  output logic [6:0]  seg_ones_o,   // HEX0 {a,b,c,d,e,f,g}  -> unidades
  output logic [6:0]  seg_tens_o    // HEX1 {a,b,c,d,e,f,g}  -> decenas
);

  // ===== 1) Pixel clock =====
  logic vgaclk;
`ifdef USE_PLL
  pll vgapll(.inclk0(clk), .c0(vgaclk));   // 25.175 MHz típico
`else
  gen_pixclk #(
    .SYS_CLK_HZ(50_000_000),
    .PIX_CLK_HZ(25_000_000)
  ) u_pix (
    .clk    (clk),
    .rst    (~rst_n),
    .clk_pix(vgaclk)
  );
`endif

  assign vga_clk    = vgaclk;
  assign vga_sync_n = 1'b1;

  // ===== 2) Controlador VGA 640x480@60 =====
  logic [9:0] x, y;
  logic       blank_b;

  vgaController u_ctrl(
    .vgaclk (vgaclk),
    .rst    (~rst_n),
    .hsync  (hsync),
    .vsync  (vsync),
    .sync_b (),
    .blank_b(blank_b),
    .x      (x),
    .y      (y)
  );

  // ADV7123: BLANK_N activo bajo → 1 = visible
  assign vga_blank_n = blank_b;

  // ===== 3) Generación de video =====
  videoGen u_vid(
    .x(x),
    .y(y),
    .visible(blank_b),
    .r(vga_r),
    .g(vga_g),
    .b(vga_b)
  );

  // ===== 4) Tick de 1 Hz =====
  logic t1hz;
  tick_1hz #(.SYS_CLK_HZ(50_000_000)) u_div1hz (
    .clk     (clk),
    .rst_n   (rst_n),
    .tick_1hz(t1hz)
  );

  // ===== 5) Temporizador 15→0 s =====
  // Pulso de start automático tras reset
  logic [1:0] start_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) start_cnt <= 2'd0;
    else if (start_cnt != 2'd3) start_cnt <= start_cnt + 2'd1;
  end
  logic start15;
  assign start15 = (start_cnt == 2'd1);

  logic pause15  = 1'b0;
  logic reload15 = 1'b0;

  logic [4:0] sec_left;
  logic       time_up;

  timer_15s #(.START_VAL(15)) u_tmr (
    .clk     (clk),
    .rst_n   (rst_n),
    .tick_1hz(t1hz),
    .start   (start15),
    .pause   (pause15),
    .reload  (reload15),
    .sec     (sec_left),
    .expired (time_up)
  );

  // (Opcional) auto-reload al expirar:
  // assign reload15 = time_up;

  // ===== 6) BCD para decenas/unidades =====
  logic [3:0] d_tens, d_ones;
  assign d_tens = (sec_left >= 10) ? 4'd1 : 4'd0;
  assign d_ones = (sec_left >= 10) ? (sec_left - 10) : sec_left[3:0];

  // ===== 7) Dos decodificadores — SIN multiplex =====
  // ACTIVE_LOW=1 porque los HEX suelen ser activos en 0
  bcd7seg #(
	.ACTIVE_LOW(1),
	.M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0)
	) u7_units (.bcd(d_ones), .seg(seg_ones_o));

	bcd7seg #(
	.ACTIVE_LOW(1),
	.M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0)
	) u7_tens  (.bcd(d_tens),  .seg(seg_tens_o));

endmodule
