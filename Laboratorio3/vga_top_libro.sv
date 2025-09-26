// vga_top_libro.sv — ÚNICO TOP: 2 jugadores, NEXT/SEL, LEDs de turno,
// displays de tiempo y de marcador por jugador, timeout con auto-jugada,
// y reinicios del temporizador según reglas del juego.
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

  // 7 segmentos (tiempo del turno, sin multiplex)
  output logic [6:0]  seg_ones_o,   // HEX0
  output logic [6:0]  seg_tens_o,   // HEX1

  // 7 segmentos (marcadores: un dígito para cada jugador)
  output logic [6:0]  seg_p1_o,     // HEX? P1
  output logic [6:0]  seg_p2_o,     // HEX? P2

  // LEDs de turno (activos en alto)
  output logic        led_p1,
  output logic        led_p2
);

  // ===== 1) Pixel clock =====
  logic vgaclk;
`ifdef USE_PLL
  pll vgapll(.inclk0(clk), .c0(vgaclk));      // 25.175 MHz típico
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
  assign vga_sync_n = 1'b1; // no usamos sync compuesto

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

  // ===== 3) Ticks: 1 Hz (timer/blink) y ~20 Hz (pausas mismatch) =====
  logic t1hz, t20hz;

  tick_1hz  #(.SYS_CLK_HZ(50_000_000)) u_div1hz (.clk(clk), .rst_n(rst_n), .tick_1hz(t1hz));
  tick_20hz                             u_div20 (.clk(clk), .rst_n(rst_n), .tick(t20hz));

  // ===== 4) Botones: debounce + one-pulse + gating 10ms tras reset =====
  logic p_next, p_sel;

  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bn (.clk(clk), .rst_n(rst_n), .btn_async(btn_next), .pulse(p_next));
  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bs (.clk(clk), .rst_n(rst_n), .btn_async(btn_sel ), .pulse(p_sel));

  localparam int INPUT_BLOCK_CYCLES = 500_000; // ~10 ms @ 50 MHz
  logic [$clog2(INPUT_BLOCK_CYCLES):0] ib_cnt;
  logic inputs_en;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ib_cnt    <= '0;
      inputs_en <= 1'b0;
    end else if (!inputs_en) begin
      if (ib_cnt == INPUT_BLOCK_CYCLES-1) inputs_en <= 1'b1;
      else                                ib_cnt    <= ib_cnt + 1'b1;
    end
  end

  logic p_next_ok, p_sel_ok;
  assign p_next_ok = p_next & inputs_en;
  assign p_sel_ok  = p_sel  & inputs_en;

  // ===== 5) PRBS/LFSR de 8 bits para azar (usamos 4 LSB) =====
  logic [7:0] prbs_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prbs_q <= 8'hA5; // semilla no nula
    end else begin
      // Polinomio: x^8 + x^6 + x^5 + x^4 + 1 (taps 7,5,4,3)
      prbs_q <= {prbs_q[6:0], prbs_q[7]^prbs_q[5]^prbs_q[4]^prbs_q[3]};
    end
  end
  logic [3:0] rnd4;
  assign rnd4 = prbs_q[3:0];

  // ===== 6) FSM del juego (única FSM: juego + displays de marcador) =====
  // Layout fijo (dos copias 0..7 barajadas); cambia si quieres
  localparam logic [3:0] LAYOUT [16] = '{
    4, 0, 7, 3, 6, 2, 5, 1,
    1, 5, 2, 6, 3, 7, 0, 4
  };

  card_state_e st  [15:0];
  logic [3:0]  sid [15:0];
  logic [3:0]  hi;

  logic        start_turn_pulse;     // para reiniciar timer en cambios de turno
  logic        restart_timer_pulse;  // para reiniciar timer en acierto/auto
  logic [3:0]  p1_score, p2_score;

  // Señales del timer (definidas más abajo) usadas como entrada a la FSM
  logic [4:0] sec_left;
  logic       time_up;

  fsm_memoria #(
    .N_CARDS(16),
    .REVEAL_PAUSE_TICKS(12),
    .EXTRA_TURN_ON_MATCH(1'b1),
    .DISP_ACTIVE_LOW(1'b1)      // 7seg activos en bajo
  ) u_game (
    .clk             (clk),
    .rst_n           (rst_n),
    .btn_next_i      (p_next_ok),
    .btn_sel_i       (p_sel_ok),
    .tick_fast_i     (t20hz),
    .tick_blink_i    (t1hz),          // blink 1 Hz para displays de marcador
    .time_up_i       (time_up),       // timeout del turno
    .rnd4_i          (rnd4),          // fuente de azar
    .layout          (LAYOUT),
    .state           (st),
    .symbol_id       (sid),
    .highlight_idx   (hi),
    .led_p1_o        (led_p1),
    .led_p2_o        (led_p2),
    .start_turn_o    (start_turn_pulse),
    .restart_timer_o (restart_timer_pulse),
    .p1_score_o      (p1_score),
    .p2_score_o      (p2_score),
    .seg_p1_o        (seg_p1_o),      // display P1 desde la FSM
    .seg_p2_o        (seg_p2_o)       // display P2 desde la FSM
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

  // ===== 8) Temporizador 15→0 s por turno =====
  // Arranque inicial + reinicios en: cambio de turno, acierto y auto-selección
  logic start15_boot;
  logic [1:0] start_cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) start_cnt <= 2'd0;
    else if (start_cnt != 2'd3) start_cnt <= start_cnt + 2'd1;
  end

  assign start15_boot = (start_cnt == 2'd1);

  // Pulso total de recarga para el timer
  logic start15_any;
  assign start15_any = start15_boot | start_turn_pulse | restart_timer_pulse;

  timer_15s #(.START_VAL(15)) u_tmr (
    .clk     (clk),
    .rst_n   (rst_n),
    .tick_1hz(t1hz),
    .start   (start15_any),  // recarga en inicio/cambio/acierto/auto
    .pause   (1'b0),
    .reload  (1'b0),
    .sec     (sec_left),
    .expired (time_up)
  );

  // 7-seg para el tiempo del turno (HEX0..HEX1)
  logic [3:0] d_tens, d_ones;
  assign d_tens = (sec_left >= 10) ? 4'd1 : 4'd0;
  assign d_ones = (sec_left >= 10) ? (sec_left - 10) : sec_left[3:0];

  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u7_ones (.bcd(d_ones), .seg(seg_ones_o));

  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u7_tens (.bcd(d_tens), .seg(seg_tens_o));

endmodule
