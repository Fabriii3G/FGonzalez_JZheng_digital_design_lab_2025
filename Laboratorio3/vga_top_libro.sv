module vga_top_libro(
  input  logic        clk,
  input  logic        rst_n,
  output logic        hsync,
  output logic        vsync,
  output logic        vga_clk,
  output logic        vga_blank_n,
  output logic        vga_sync_n,
  output logic [7:0]  vga_r,
  output logic [7:0]  vga_g,
  output logic [7:0]  vga_b
);

  // ===== 1) Pixel clock =====
  logic vgaclk;

`ifdef USE_PLL
  pll vgapll(.inclk0(clk), .c0(vgaclk));   // 25.175 MHz
`else
  gen_pixclk #(
    .SYS_CLK_HZ(50_000_000),   // AJUSTA a 50e6 o 100e6 según tu placa
    .PIX_CLK_HZ(25_000_000)
  ) u_pix (
    .clk    (clk),
    .rst    (~rst_n),
    .clk_pix(vgaclk)
  );
`endif

  assign vga_clk    = vgaclk;
  assign vga_sync_n = 1'b1;    // no usamos composite sync

  // ===== 2) Controlador VGA 640x480@60 =====
  logic [9:0] x, y;
  logic       blank_b;          // 1 dentro de área visible

  vgaController u_ctrl(
    .vgaclk (vgaclk),
    .rst    (~rst_n),
    .hsync  (hsync),
    .vsync  (vsync),
    .sync_b (),                 // sin usar
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
    .visible(blank_b),   // <--- PASA visible desde el controlador
    .r(vga_r),
    .g(vga_g),
    .b(vga_b)
  );

endmodule
