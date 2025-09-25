// vga_top_libro.sv
// Top mínimo "estilo libro": genera 640x480@60 y dibuja texto/rectángulo.
// Opción de reloj: USE_PLL -> instancia PLL; si no, usa divisor a 25.000 MHz.

module vga_top_libro(
  input  logic        clk,          // clock de placa (50 MHz o 100 MHz)
  input  logic        rst_n,        // reset activo en bajo (puedes amarrarlo a 1'b1)
  output logic        hsync,
  output logic        vsync,
  output logic        vga_clk,      // a pin VGA_CLK
  output logic        vga_blank_n,  // a pin VGA_BLANK_N (1 = visible)
  output logic        vga_sync_n,   // a pin VGA_SYNC_N (déjalo en 1)
  output logic [7:0]  vga_r,
  output logic [7:0]  vga_g,
  output logic [7:0]  vga_b
);

  // ===== 1) Pixel clock: PLL (recomendado) o divisor (rápido) =====
  logic vgaclk;

`ifdef USE_PLL
  // Debes generar un IP "pll" (ALTPLL) con .inclk0=clk y .c0=25.175 MHz
  pll vgapll(.inclk0(clk), .c0(vgaclk));
`else
  // Divisor a 25.000 MHz (sirve para probar; muchos monitores lo aceptan)
  gen_pixclk #(
    .SYS_CLK_HZ(50_000_000),   // <-- AJUSTA a tu oscilador real (50e6 o 100e6)
    .PIX_CLK_HZ(25_000_000)
  ) u_pix (
    .clk    (clk),
    .rst    (~rst_n),
    .clk_pix(vgaclk)
  );
`endif

  assign vga_clk    = vgaclk;
  assign vga_sync_n = 1'b1;     // composite sync no usada

  // ===== 2) Controlador VGA (timings 640x480@60) =====
  logic [9:0] x, y;
  logic       blank_b;          // 1 en área visible

  vgaController u_ctrl(
    .vgaclk (vgaclk),
    .rst    (~rst_n),
    .hsync  (hsync),
    .vsync  (vsync),
    .sync_b (),                 // no usado
    .blank_b(blank_b),
    .x      (x),
    .y      (y)
  );

  // ADV7123: BLANK_N activo en bajo → BLANK_N = 1 cuando visible
  assign vga_blank_n = blank_b;

  // ===== 3) Generación de video (texto + rectángulo) =====
  videoGen u_vid(
    .x(x),
    .y(y),
    .r(vga_r),
    .g(vga_g),
    .b(vga_b)
  );

endmodule
