// vga_top_libro.sv — VGA + juego memoria 4x4 con 2 botones (NEXT/SEL)
// - Genera video vía videoGen (recibe state/symbol_id/hi desde FSM)
// - Cuenta regresiva 15→0 en HEX1..HEX0 (sin multiplex)
// - Anti-rebote + pulso por botón, y **gating 10 ms** tras reset para evitar pulsos fantasma
//
// Requiere en el proyecto:
//   lab3_params.sv, vgaController.sv, gen_pixclk.sv o PLL (definir USE_PLL si usas PLL),
//   videoGen.sv (que recibe state/symbol_id/hi), vga_cards.sv, bcd7seg.sv (ACTIVE_LOW=1),
//   tick_1hz.sv, tick_20hz.sv, btn_onepulse.sv, fsm_memoria.sv

import lab3_params::*;

module vga_top_libro(
  input  logic        clk,
  input  logic        rst_n,

  // Botones (nivel crudo del pin, activo en 1)
  input  logic        btn_next,
  input  logic        btn_sel,

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
  output logic [6:0]  seg_ones_o,   // HEX0 {a,b,c,d,e,f,g} -> unidades
  output logic [6:0]  seg_tens_o    // HEX1 {a,b,c,d,e,f,g} -> decenas
);

  // ===== 1) Pixel clock =====
  logic vgaclk;
`ifdef USE_PLL
  pll vgapll(.inclk0(clk), .c0(vgaclk));     // 25.175 MHz típico
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
  assign vga_sync_n = 1'b1; // no se usa sync compuesto

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

  // ===== 3) Ticks: 1 Hz (timer) y ~20 Hz (pausa mismatch) =====
  logic t1hz, t20hz;

  tick_1hz #(.SYS_CLK_HZ(50_000_000)) u_div1hz (
    .clk     (clk),
    .rst_n   (rst_n),
    .tick_1hz(t1hz)
  );

  tick_20hz u_div20 (
    .clk (clk),
    .rst_n(rst_n),
    .tick(t20hz)
  );

  // ===== 4) Botones → anti-rebote + pulso =====
  logic p_next, p_sel;

  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bn ( // ~5 ms @ 50 MHz
    .clk      (clk),
    .rst_n    (rst_n),
    .btn_async(btn_next),
    .pulse    (p_next)
  );

  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bs (
    .clk      (clk),
    .rst_n    (rst_n),
    .btn_async(btn_sel),
    .pulse    (p_sel)
  );

  // ===== 5) [NUEVO] Gating de entradas tras reset (~10 ms) =====
  localparam int INPUT_BLOCK_CYCLES = 500_000; // 10 ms @ 50 MHz
  logic [$clog2(INPUT_BLOCK_CYCLES):0] ib_cnt;
  logic inputs_en;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ib_cnt    <= '0;
      inputs_en <= 1'b0;
    end else if (!inputs_en) begin
      if (ib_cnt == INPUT_BLOCK_CYCLES-1) begin
        inputs_en <= 1'b1;
      end else begin
        ib_cnt <= ib_cnt + 1'b1;
      end
    end
  end

  // Versión enmascarada de los pulsos (conecta estos a la FSM)
  logic p_next_ok, p_sel_ok;
  assign p_next_ok = p_next & inputs_en;
  assign p_sel_ok  = p_sel  & inputs_en;

  // ===== 6) FSM del juego (estado de cartas, símbolos, highlight) =====
  // Layout fijo (dos copias 0..7 barajadas); puedes cambiarlo
  localparam logic [3:0] LAYOUT [16] = '{
    4, 0, 7, 3, 6, 2, 5, 1,
    1, 5, 2, 6, 3, 7, 0, 4
  };

  card_state_e st  [15:0];
  logic [3:0]  sid [15:0];
  logic [3:0]  hi;

  fsm_memoria #(
    .N_CARDS(16),
    .REVEAL_PAUSE_TICKS(12),      // ~600 ms con t20hz (12*50 ms)
    .EXTRA_TURN_ON_MATCH(1'b1)    // turno extra al acertar
  ) u_game (
    .clk         (clk),
    .rst_n       (rst_n),
    .btn_next_i  (p_next_ok),   // ← enmascarados
    .btn_sel_i   (p_sel_ok),    // ← enmascarados
    .tick_fast_i (t20hz),
    .layout      (LAYOUT),
    .state       (st),
    .symbol_id   (sid),
    .highlight_idx(hi)
  );

  // ===== 7) Video =====
  videoGen u_vid(
    .x(x),
    .y(y),
    .visible(blank_b),
    .state(st),
    .symbol_id(sid),
    .hi(hi),
    .r(vga_r),
    .g(vga_g),
    .b(vga_b)
  );

  // ===== 8) Temporizador 15→0 s (independiente del juego) =====
  // Pulso de start automático tras reset (pequeño contador)
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

  // ===== 9) BCD para decenas/unidades y 7 segmentos (sin multiplex) =====
  logic [3:0] d_tens, d_ones;
  assign d_tens = (sec_left >= 10) ? 4'd1 : 4'd0;
  assign d_ones = (sec_left >= 10) ? (sec_left - 10) : sec_left[3:0];

  // ACTIVE_LOW=1 porque los HEX suelen ser activos en 0
  bcd7seg #(
    .ACTIVE_LOW(1),
    .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0)
  ) u7_units (
    .bcd(d_ones),
    .seg(seg_ones_o)
  );

  bcd7seg #(
    .ACTIVE_LOW(1),
    .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0)
  ) u7_tens  (
    .bcd(d_tens),
    .seg(seg_tens_o)
  );

endmodule
