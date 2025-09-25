// top_lab3_avance.sv — Integración “estilo libro” + cartas
import lab3_params::*;

module top_lab3_avance(
  input  logic        clk,        // clock de placa (50/100 MHz)
  input  logic        rst,
  input  logic        btn_ok,     // debounced/oneshot

  output logic        hsync,
  output logic        vsync,
  output logic        vga_clk,      // a VGA_CLK
  output logic        vga_blank_n,  // a VGA_BLANK_N (1 = visible)
  output logic        vga_sync_n,   // a VGA_SYNC_N (déjalo en 1)
  output logic [7:0]  vga_r,
  output logic [7:0]  vga_g,
  output logic [7:0]  vga_b
);
  // ---------------- 1) PLL 25.175 MHz (libro) ----------------
  logic vgaclk;
	gen_pixclk #(.SYS_CLK_HZ(SYS_CLK_HZ), .PIX_CLK_HZ(PIX_CLK_HZ)) u_pix(
	  .clk(clk), .rst(rst), .clk_pix(vgaclk)
	);
	assign vga_clk   = vgaclk;
	assign vga_sync_n= 1'b1;

  // ---------------- 2) Controlador VGA (libro) ----------------
  logic [9:0] x, y;
  logic       blank_b;      // 1 en área visible
  vgaController u_ctrl(
    .vgaclk (vgaclk),
    .rst    (rst),
    .hsync  (hsync),
    .vsync  (vsync),
    .sync_b (),             // opcional: no usado
    .blank_b(blank_b),
    .x      (x),
    .y      (y)
  );
  // ADV7123: BLANK_N activo en bajo → BLANK_N = 1 cuando visible
  assign vga_blank_n = blank_b;

  // ---------------- 3) Tick 1 Hz + contador 15 s --------------
  logic tick1s;
  tick_1hz #(.SYS_CLK_HZ(SYS_CLK_HZ)) u_1hz (
    .clk     (clk),     // reloj de sistema
    .rst     (rst),
    .tick_1s (tick1s)
  );

  logic        timer_load, timer_en, timeout_15s;
  logic [3:0]  bcd_t, bcd_u;

  countdown_15s u_cd (
    .clk       (clk),
    .rst       (rst),
    .tick_1s   (tick1s),
    .load      (timer_load),
    .en        (timer_en),
    .timeout   (timeout_15s),
    .bcd_tens  (bcd_t),
    .bcd_units (bcd_u)
  );

  // ---------------- 4) FSM (avance) ---------------------------
  logic        open_en;
  logic [3:0]  open_idx;
  logic [3:0]  highlight_idx;

  fsm_memoria u_fsm (
    .clk          (clk),        // lógica a clk de sistema
    .rst          (rst),
    .btn_ok       (btn_ok),
    .timeout_15s  (timeout_15s),
    .timer_load   (timer_load),
    .timer_en     (timer_en),
    .open_en      (open_en),
    .open_idx     (open_idx),
    .highlight_idx(highlight_idx)
  );

  // ---------------- 5) Banco de cartas ------------------------
  lab3_params::card_state_e st [16];
  logic [3:0]              sid [16];

  card_bank u_bank (
    .clk            (clk),
    .rst            (rst),
    .open_en        (open_en),
    .open_idx       (open_idx),
    .close_pair_en  (1'b0),
    .close_a        (4'd0),
    .close_b        (4'd0),
    .lock_pair_en   (1'b0),
    .lock_a         (4'd0),
    .lock_b         (4'd0),
    .state          (st),
    .symbol_id      (sid)
  );

  // ---------------- 6) Render de cartas -----------------------
  // Sustituye el "videoGen" del libro por tu "vga_cards".
  // visible = blank_b (1 dentro de 640x480)
  vga_cards u_cards (
    .clk           (vgaclk),     // render al pixel clock
    .x             (x),
    .y             (y),
    .visible       (blank_b),
    .state         (st),
    .symbol_id     (sid),
    .highlight_idx (highlight_idx),
    .R             (vga_r),
    .G             (vga_g),
    .B             (vga_b)
  );

endmodule
