// fsm_memoria.sv — ÚNICA FSM: memoria 4x4 de 2 jugadores + marcadores en 7seg con blink.
// - Timeout: auto-jugada al azar
// - Turno extra al acertar + reinicio de temporizador
// - Displays de marcador (un dígito por jugador) con parpadeo del jugador activo
import lab3_params::*;

module fsm_memoria #(
  parameter int N_CARDS = 16,
  parameter int REVEAL_PAUSE_TICKS = 12,    // ~600 ms si tick_fast_i=20 Hz
  parameter bit EXTRA_TURN_ON_MATCH = 1'b1,
  parameter bit DISP_ACTIVE_LOW     = 1'b1  // 7seg activos en bajo
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // Botones (one-pulse, ya enmascarados en el top)
  input  logic                 btn_next_i,
  input  logic                 btn_sel_i,

  // Relojes auxiliares
  input  logic                 tick_fast_i,   // ~20Hz para pausa
  input  logic                 tick_blink_i,  // ~1Hz para parpadeo displays

  // Timeout del turno (pulso 1 ciclo cuando expira 15 s)
  input  logic                 time_up_i,

  // Aleatorio (4 bits) para elegir índice de partida
  input  logic [3:0]           rnd4_i,

  // Layout de símbolos (dos copias 0..7 barajadas)
  input  logic [3:0]           layout   [N_CARDS-1:0],

  // Salidas a video
  output card_state_e          state    [N_CARDS-1:0],
  output logic         [3:0]   symbol_id[N_CARDS-1:0],
  output logic         [3:0]   highlight_idx,

  // LEDs de turno (activos en alto)
  output logic                 led_p1_o,
  output logic                 led_p2_o,

  // Control de temporizador
  output logic                 start_turn_o,     // pulso al iniciar turno (cambio jugador)
  output logic                 restart_timer_o,  // pulso para reiniciar a 15s (acierto / auto)

  // Marcadores (numéricos, por si los quieres en video)
  output logic [3:0]           p1_score_o,
  output logic [3:0]           p2_score_o,

  // Displays de marcador (un dígito por jugador)
  output logic [6:0]           seg_p1_o,
  output logic [6:0]           seg_p2_o
);

  // ---------------- Registros de juego ----------------
  card_state_e st_q [N_CARDS], st_d [N_CARDS];
  logic [3:0]  sid_q[N_CARDS];

  logic [3:0]  hi_q, hi_d;
  logic [3:0]  a_idx_q, a_idx_d;
  logic [3:0]  b_idx_q, b_idx_d;

  typedef enum logic [1:0] {S_IDLE, S_ONE, S_PAUSE} fsm_e;
  fsm_e ps_q, ps_d;

  logic [7:0]  pause_cnt_q, pause_cnt_d;

  // Turnos y marcador
  logic        cur_pl_q, cur_pl_d;         // 0=P1, 1=P2
  logic [3:0]  p1_score_q, p1_score_d;
  logic [3:0]  p2_score_q, p2_score_d;

  // Pulsos a temporizador
  logic        start_turn_q, start_turn_d;
  logic        restart_timer_q, restart_timer_d;

  // Blink (1 Hz)
  logic blink_q, blink_d;

  // --------- Temporales para auto-jugada (nivel módulo por compatibilidad) ---------
  logic [3:0] pick1, pick2;

  // ---------------- Helpers ----------------
  function automatic logic [3:0] next_alive(input logic [3:0] cur);
    logic [3:0] k;
    next_alive = cur;
    for (int step=1; step<=N_CARDS; step++) begin
      k = (cur + step[3:0]) & 4'hF;
      if (st_q[k] != CARD_MATCH) begin
        next_alive = k;
        break;
      end
    end
  endfunction

  function automatic logic [3:0] pick_down_excl(
      input logic [3:0] start,
      input logic       use_excl,
      input logic [3:0] excl_idx
  );
    logic [3:0] k;
    pick_down_excl = 4'hF;
    for (int step=0; step<N_CARDS; step++) begin
      k = (start + step[3:0]) & 4'hF;
      if ((st_q[k] != CARD_MATCH) && (st_q[k] == CARD_DOWN)) begin
        if (!(use_excl && (k==excl_idx))) begin
          pick_down_excl = k;
          break;
        end
      end
    end
  endfunction

  // ---------------- Reset / Registros ----------------
  integer j;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (j=0; j<N_CARDS; j++) begin
        st_q[j]  <= CARD_DOWN;
        sid_q[j] <= layout[j];
      end
      hi_q            <= 4'd0;
      a_idx_q         <= 4'hF;
      b_idx_q         <= 4'hF;
      ps_q            <= S_IDLE;
      pause_cnt_q     <= '0;

      cur_pl_q        <= 1'b0;      // empieza P1
      p1_score_q      <= 4'd0;
      p2_score_q      <= 4'd0;

      start_turn_q    <= 1'b1;      // primer turno (para arrancar timer en top)
      restart_timer_q <= 1'b0;

      blink_q         <= 1'b0;
    end else begin
      for (j=0; j<N_CARDS; j++) st_q[j] <= st_d[j];
      hi_q            <= hi_d;
      a_idx_q         <= a_idx_d;
      b_idx_q         <= b_idx_d;
      ps_q            <= ps_d;
      pause_cnt_q     <= pause_cnt_d;

      cur_pl_q        <= cur_pl_d;
      p1_score_q      <= p1_score_d;
      p2_score_q      <= p2_score_d;

      start_turn_q    <= start_turn_d;
      restart_timer_q <= restart_timer_d;

      blink_q         <= blink_d;
    end
  end

  // ---------------- Next-state (juego) ----------------
  always_comb begin
    // defaults
    for (int i=0; i<N_CARDS; i++) st_d[i] = st_q[i];
    hi_d            = hi_q;
    a_idx_d         = a_idx_q;
    b_idx_d         = b_idx_q;
    ps_d            = ps_q;
    pause_cnt_d     = pause_cnt_q;

    cur_pl_d        = cur_pl_q;
    p1_score_d      = p1_score_q;
    p2_score_d      = p2_score_q;

    start_turn_d    = 1'b0;
    restart_timer_d = 1'b0;

    // Defaults para temporales (evita latches)
    pick1 = 4'hF;
    pick2 = 4'hF;

    // navegación
    if (btn_next_i) hi_d = next_alive(hi_q);

    // ---------- TIMEOUT: auto-jugada ----------
    if (time_up_i) begin
      unique case (ps_q)
        S_IDLE: begin
          // Elegir UNA carta al azar (DOWN y no MATCH)
          pick1 = pick_down_excl(rnd4_i, 1'b0, 4'h0);
          if (pick1 != 4'hF) begin
            st_d[pick1] = CARD_UP;
            a_idx_d     = pick1;
            b_idx_d     = 4'hF;
            hi_d        = pick1;
            ps_d        = S_ONE;
            restart_timer_d = 1'b1; // dar margen a elegir 2ª
          end
        end

        S_ONE: begin
          // Elegir SEGUNDA carta al azar (DOWN, no MATCH, distinta de a_idx_q)
          pick2 = pick_down_excl(rnd4_i, 1'b1, a_idx_q);
          if (pick2 != 4'hF) begin
            st_d[pick2] = CARD_UP;
            b_idx_d     = pick2;
            hi_d        = pick2;
            if (sid_q[a_idx_q] == sid_q[pick2]) begin
              st_d[a_idx_q] = CARD_MATCH;
              st_d[pick2]   = CARD_MATCH;
              if (!cur_pl_q) p1_score_d = p1_score_q + 4'd1;
              else           p2_score_d = p2_score_q + 4'd1;

              a_idx_d = 4'hF; b_idx_d = 4'hF;
              ps_d    = S_IDLE;

              // turno extra + reinicio tiempo por acierto
              restart_timer_d = 1'b1;
              if (!EXTRA_TURN_ON_MATCH) begin
                cur_pl_d     = ~cur_pl_q;
                start_turn_d = 1'b1;
              end
            end else begin
              ps_d        = S_PAUSE;
              pause_cnt_d = (REVEAL_PAUSE_TICKS==0) ? 8'd1
                                                    : REVEAL_PAUSE_TICKS[7:0];
            end
          end
        end

        default: ; // en S_PAUSE ignorar timeout
      endcase
    end

    // ---------- Flujo normal por botones ----------
    unique case (ps_q)
      S_IDLE: begin
        if (st_q[hi_q]==CARD_MATCH) hi_d = next_alive(hi_q);
        if (btn_sel_i && st_q[hi_q]==CARD_DOWN) begin
          st_d[hi_q] = CARD_UP;
          a_idx_d    = hi_q;
          b_idx_d    = 4'hF;
          ps_d       = S_ONE;
        end
      end

      S_ONE: begin
        if (btn_sel_i && st_q[hi_q]==CARD_DOWN) begin
          st_d[hi_q] = CARD_UP;
          b_idx_d    = hi_q;

          if (sid_q[a_idx_q] == sid_q[hi_q]) begin
            st_d[a_idx_q] = CARD_MATCH;
            st_d[hi_q]    = CARD_MATCH;
            if (!cur_pl_q) p1_score_d = p1_score_q + 4'd1;
            else           p2_score_d = p2_score_q + 4'd1;

            a_idx_d = 4'hF; b_idx_d = 4'hF;
            ps_d    = S_IDLE;

            // turno extra + reinicio tiempo por acierto
            restart_timer_d = 1'b1;
            if (!EXTRA_TURN_ON_MATCH) begin
              cur_pl_d     = ~cur_pl_q;
              start_turn_d = 1'b1;
            end
          end else begin
            ps_d        = S_PAUSE;
            pause_cnt_d = (REVEAL_PAUSE_TICKS==0) ? 8'd1
                                                  : REVEAL_PAUSE_TICKS[7:0];
          end
        end
      end

      S_PAUSE: begin
        if (pause_cnt_q != 0 && tick_fast_i) pause_cnt_d = pause_cnt_q - 8'd1;
        if (pause_cnt_q == 8'd1 && tick_fast_i) begin
          if (a_idx_q != 4'hF) st_d[a_idx_q] = CARD_DOWN;
          if (b_idx_q != 4'hF) st_d[b_idx_q] = CARD_DOWN;
          a_idx_d = 4'hF; b_idx_d = 4'hF;

          hi_d        = next_alive(hi_q);
          ps_d        = S_IDLE;
          cur_pl_d    = ~cur_pl_q;   // cambio de jugador por fallo
          start_turn_d= 1'b1;        // reinicio de timer (en top)
        end
      end
    endcase
  end

  // ---------------- Blink de displays ----------------
  always_comb begin
    blink_d = blink_q;
    if (tick_blink_i) blink_d = ~blink_q;  // 1 Hz típico
  end

  // ---------------- Salidas base ----------------
  generate
    genvar g;
    for (g=0; g<N_CARDS; g++) begin : G_OUTS
      assign state[g]     = st_q[g];
      assign symbol_id[g] = sid_q[g];
    end
  endgenerate

  assign highlight_idx   = hi_q;
  assign led_p1_o        = (cur_pl_q == 1'b0);
  assign led_p2_o        = (cur_pl_q == 1'b1);
  assign start_turn_o    = start_turn_q;
  assign restart_timer_o = restart_timer_q;
  assign p1_score_o      = p1_score_q;
  assign p2_score_o      = p2_score_q;

  // ---------------- Displays de marcador (aquí mismo) ----------------
  // Decodificación a 7 segmentos (fija)
  logic [6:0] seg_p1_fix, seg_p2_fix;

  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u_bcd_p1 (.bcd(p1_score_q[3:0]), .seg(seg_p1_fix));

  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u_bcd_p2 (.bcd(p2_score_q[3:0]), .seg(seg_p2_fix));

  // Apagado según polaridad
  logic [6:0] seg_off;
  assign seg_off = (DISP_ACTIVE_LOW) ? 7'b111_1111 : 7'b000_0000;

  // Parpadeo: el jugador activo alterna entre su dígito y apagado
  always_comb begin
    // por defecto: fijos
    seg_p1_o = seg_p1_fix;
    seg_p2_o = seg_p2_fix;

    if (cur_pl_q == 1'b0) begin
      // Turno P1
      seg_p1_o = (blink_q) ? seg_p1_fix : seg_off;
    end else begin
      // Turno P2
      seg_p2_o = (blink_q) ? seg_p2_fix : seg_off;
    end
  end

endmodule
