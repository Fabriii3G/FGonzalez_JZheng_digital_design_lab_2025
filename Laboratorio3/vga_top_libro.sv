// vga_top_libro.sv — agrega barajado y "Nuevo Juego"
import lab3_params::*;

module vga_top_libro(
  input  logic        clk,
  input  logic        rst_n,

  // Botones (nivel crudo del pin, activo en 1)
  input  logic        btn_next,
  input  logic        btn_sel,
  input  logic        btn_rst_game,  // <<< NUEVO: botón "Nuevo Juego" (soft reset)

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

  // 7 segmentos (marcadores)
  output logic [6:0]  seg_p1_o,
  output logic [6:0]  seg_p2_o,

  // LEDs de turno
  output logic        led_p1,
  output logic        led_p2
);

  // ===== 1) Pixel clock =====
  logic vgaclk;
`ifdef USE_PLL
  pll vgapll(.inclk0(clk), .c0(vgaclk));
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

  // ===== 2) VGA timing =====
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
  assign vga_blank_n = blank_b;

  // ===== 3) Ticks =====
  logic t1hz, t20hz;
  tick_1hz  #(.SYS_CLK_HZ(50_000_000)) u_div1hz (.clk(clk), .rst_n(rst_n), .tick_1hz(t1hz));
  tick_20hz                             u_div20 (.clk(clk), .rst_n(rst_n), .tick(t20hz));

  // ===== 4) Debounce / one-pulse =====
  logic p_next, p_sel, p_newgame;

  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bn (.clk(clk), .rst_n(rst_n), .btn_async(btn_next),     .pulse(p_next));
  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_bs (.clk(clk), .rst_n(rst_n), .btn_async(btn_sel ),     .pulse(p_sel));
  btn_onepulse #(.DEBOUNCE_CLKS(250_000)) u_br (.clk(clk), .rst_n(rst_n), .btn_async(btn_rst_game), .pulse(p_newgame));

  // Bloqueo de entradas 10 ms tras reset global
  localparam int INPUT_BLOCK_CYCLES = 500_000;
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

  logic p_next_ok, p_sel_ok, p_newgame_ok;
  assign p_next_ok    = p_next    & inputs_en;
  assign p_sel_ok     = p_sel     & inputs_en;
  assign p_newgame_ok = p_newgame & inputs_en;

  // ===== 5) PRBS libre (NO se resetea con "nuevo juego") =====
  // Se resetea solo con rst_n global -> perfecto para tomar "semillas" distintas
  logic [7:0] prbs_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) prbs_q <= 8'hA5;                         // semilla de arranque
    else        prbs_q <= {prbs_q[6:0], prbs_q[7]^prbs_q[5]^prbs_q[4]^prbs_q[3]};
  end
  logic [3:0] rnd4; assign rnd4 = prbs_q[3:0];

  // ===== 6) BARAJADOR =====
  logic                       shuf_start, shuf_busy, shuf_done;
  logic [3:0]                 layout_dyn [15:0];

  deck_shuffle16 u_shuf (
    .clk     (clk),
    .rst_n   (rst_n),
    .start_i (shuf_start),
    .seed_i  (prbs_q),     // semilla tomada del PRBS libre
    .busy_o  (shuf_busy),
    .done_o  (shuf_done),
    .layout_o(layout_dyn)
  );

  // Disparos de barajado:
  // - Al boot (una sola vez)
  // - Cada p_newgame_ok
  logic [1:0] boot_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) boot_cnt <= 2'd0;
    else if (boot_cnt != 2'd3) boot_cnt <= boot_cnt + 2'd1;
  end
  wire boot_pulse = (boot_cnt == 2'd1);

  // FSM para "Nuevo Juego": BARAJAR -> PULSO DE RESET SUAVE -> IDLE
  typedef enum logic [1:0] {NG_IDLE, NG_SHUF, NG_RST, NG_WAIT} ng_e;
  ng_e ng_q, ng_d;

  logic        rst_game_n;      // reset "suave" hacia el juego
  logic [3:0]  rst_cnt_q, rst_cnt_d;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ng_q      <= NG_IDLE;
      rst_cnt_q <= '0;
    end else begin
      ng_q      <= ng_d;
      rst_cnt_q <= rst_cnt_d;
    end
  end

  always_comb begin
    ng_d        = ng_q;
    rst_cnt_d   = rst_cnt_q;
    shuf_start  = 1'b0;

    unique case (ng_q)
      NG_IDLE: begin
        if (boot_pulse || p_newgame_ok) begin
          shuf_start = 1'b1;
          ng_d       = NG_SHUF;
        end
      end

      NG_SHUF: begin
        // esperar a que el barajador termine
        if (shuf_done) begin
          // pasar a reset suave 2..3 ciclos para cargar layout en reset
          rst_cnt_d = 4'd3;
          ng_d      = NG_RST;
        end
      end

      NG_RST: begin
        // mientras rst_cnt>0 mantenemos reset bajo
        if (rst_cnt_q != 0) rst_cnt_d = rst_cnt_q - 4'd1;
        else                ng_d      = NG_WAIT;
      end

      NG_WAIT: begin
        // colchón de 1-2 ciclos luego del reset suave
        ng_d = NG_IDLE;
      end
    endcase
  end

  // reset suave activo en bajo cuando NG_RST
  assign rst_game_n = (ng_q == NG_RST) ? 1'b0 : 1'b1;

  // ===== 7) Señales del juego =====
  card_state_e st  [15:0];
  logic [3:0]  sid [15:0];
  logic [3:0]  hi;

  logic        start_turn_pulse;
  logic        restart_timer_pulse;
  logic [3:0]  p1_score, p2_score;

  logic [4:0]  sec_left;
  logic        time_up;

  logic game_over, winner_p2, tie;

  // NOTA: rst hacia el juego = rst_n (global) Y rst_game_n (suave)
  wire rst_game_total_n = rst_n & rst_game_n;

  fsm_memoria #(
    .N_CARDS(16),
    .REVEAL_PAUSE_TICKS(12),
    .EXTRA_TURN_ON_MATCH(1'b1),
    .DISP_ACTIVE_LOW(1'b1)
  ) u_game (
    .clk             (clk),
    .rst_n           (rst_game_total_n),   // <<< reset suave integrado
    .btn_next_i      (p_next_ok),
    .btn_sel_i       (p_sel_ok),
    .tick_fast_i     (t20hz),
    .tick_blink_i    (t1hz),
    .time_up_i       (time_up),
    .rnd4_i          (rnd4),
    .layout          (layout_dyn),         // <<< layout barajado dinámico
    .state           (st),
    .symbol_id       (sid),
    .highlight_idx   (hi),
    .led_p1_o        (led_p1),
    .led_p2_o        (led_p2),
    .start_turn_o    (start_turn_pulse),
    .restart_timer_o (restart_timer_pulse),
    .p1_score_o      (p1_score),
    .p2_score_o      (p2_score),
    .seg_p1_o        (seg_p1_o),
    .seg_p2_o        (seg_p2_o),
    .game_over_o     (game_over),
    .winner_p2_o     (winner_p2),
    .tie_o           (tie)
  );

  // ===== 8) Video =====
  videoGen u_vid(
    .x(x),
    .y(y),
    .visible(blank_b),
    .state(st),
    .symbol_id(sid),
    .hi(hi),
    .game_over(game_over),
    .winner_p2(winner_p2),
    .tie(tie),
    .r(vga_r),
    .g(vga_g),
    .b(vga_b)
  );

  // ===== 9) Temporizador por turno =====
  // Arranque y restart ya vienen de la FSM; añadimos un pulso al boot
  logic start15_boot; logic [1:0] start_cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) start_cnt <= 2'd0;
    else if (start_cnt != 2'd3) start_cnt <= start_cnt + 2'd1;
  end
  assign start15_boot = (start_cnt == 2'd1);

  logic start15_any;
  assign start15_any = start15_boot | start_turn_pulse | restart_timer_pulse;

  timer_15s #(.START_VAL(15)) u_tmr (
    .clk     (clk),
    .rst_n   (rst_game_total_n),  // si reinicias juego, reinicia timer también
    .tick_1hz(t1hz),
    .start   (start15_any),
    .pause   (1'b0),
    .reload  (1'b0),
    .sec     (sec_left),
    .expired (time_up)
  );

  // 7-seg del tiempo (igual que ya tenías), con override “– –” al terminar
  logic [3:0] d_tens, d_ones;
  assign d_tens = (sec_left >= 10) ? 4'd1 : 4'd0;
  assign d_ones = (sec_left >= 10) ? (sec_left - 10) : sec_left[3:0];

  logic [6:0] seg_ones_w, seg_tens_w;
  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u7_ones (.bcd(d_ones), .seg(seg_ones_w));
  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u7_tens (.bcd(d_tens), .seg(seg_tens_w));

  localparam logic [6:0] SEG_DASH_TIME = 7'b111_1110; // solo 'g'
  localparam logic [6:0] SEG_OFF_TIME  = 7'b111_1111;

  always_comb begin
    if (game_over) begin
      seg_ones_o = t1hz ? SEG_DASH_TIME : SEG_OFF_TIME;
      seg_tens_o = t1hz ? SEG_DASH_TIME : SEG_OFF_TIME;
    end else begin
      seg_ones_o = seg_ones_w;
      seg_tens_o = seg_tens_w;
    end
  end

endmodule
