// game_datapath.sv - Manejo de datos del juego (cartas, puntajes, etc.)
// Variante: auto–selección de PAR en el mismo ciclo usando dos nibbles de rnd8_i
import lab3_params::*;

module game_datapath #(
  parameter int N_CARDS = 16,
  parameter int REVEAL_PAUSE_TICKS = 12,
  parameter bit EXTRA_TURN_ON_MATCH = 1'b1,
  parameter bit DISP_ACTIVE_LOW     = 1'b1
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // Control desde FSM
  input  logic                 select_first_card_i,
  input  logic                 select_second_card_i,
  input  logic                 auto_select_first_i,   // usado solo en flujo manual S_ONE
  input  logic                 auto_select_second_i,  // usado solo en flujo manual S_ONE
  input  logic                 auto_select_pair_i,    // <<< NUEVO: auto–par en S_IDLE
  input  logic                 match_found_i,         // no usado internamente (telemetría)
  input  logic                 start_pause_i,
  input  logic                 end_turn_i,
  input  logic                 extra_turn_i,          // no usado internamente (telemetría)

  // Entradas externas
  input  logic                 btn_next_i,
  input  logic                 tick_fast_i,
  input  logic                 tick_blink_i,
  input  logic [7:0]           rnd8_i,                
  input  logic [3:0]           layout [N_CARDS-1:0],

  // Salidas a FSM
  output logic                 cards_match_o,
  output logic                 pause_done_o,
  output logic                 auto_pick1_valid_o,
  output logic                 auto_pick2_valid_o,
  output logic                 match_happened_o,
  output logic                 manual_pick2_valid_o,

  // Salidas del juego
  output card_state_e          state    [N_CARDS-1:0],
  output logic         [3:0]   symbol_id[N_CARDS-1:0],
  output logic         [3:0]   highlight_idx,
  output logic                 led_p1_o,
  output logic                 led_p2_o,
  output logic                 start_turn_o,
  output logic [3:0]           p1_score_o,
  output logic [3:0]           p2_score_o,
  output logic [6:0]           seg_p1_o,
  output logic [6:0]           seg_p2_o,

  // Fin de juego y resultado
  output logic                 game_over_o,
  output logic                 winner_p2_o,
  output logic                 tie_o
);

  // ============ Registros ============
  card_state_e st_q [N_CARDS], st_d [N_CARDS];
  logic [3:0]  sid_q[N_CARDS];
  logic [3:0]  hi_q, hi_d;
  logic [4:0]  a_idx_q, a_idx_d;  // 31 = inválido
  logic [4:0]  b_idx_q, b_idx_d;
  logic [7:0]  pause_cnt_q, pause_cnt_d;
  logic        cur_pl_q, cur_pl_d;
  logic [3:0]  p1_score_q, p1_score_d;
  logic [3:0]  p2_score_q, p2_score_d;
  logic        start_turn_q, start_turn_d;
  logic        blink_q, blink_d;
  logic [3:0]  rnd_captured_q, rnd_captured_d;  // captura para flujo manual

  // ============ Funciones auxiliares ============
  function automatic logic [3:0] next_alive(input logic [3:0] cur);
    logic [3:0] k; logic found;
    next_alive = cur; found = 1'b0;
    for (int step=1; step<=N_CARDS && !found; step++) begin
      k = (cur + step[3:0]) & 4'hF;
      if (st_q[k] == CARD_DOWN) begin
        next_alive = k; found = 1'b1;
      end
    end
  endfunction

  function automatic logic [3:0] pick_down_excl(
      input logic [3:0] start,
      input logic       use_excl,
      input logic [3:0] excl_idx
  );
    logic [3:0] k; logic found;
    pick_down_excl = 4'hF; found = 1'b0;
    for (int step=0; step<N_CARDS && !found; step++) begin
      k = (start + step[3:0]) & 4'hF;
      if (st_q[k] == CARD_DOWN) begin
        if (!(use_excl && (k == excl_idx))) begin
          pick_down_excl = k; found = 1'b1;
        end
      end
    end
  endfunction

  // ============ Registros ============
  integer j;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (j=0; j<N_CARDS; j++) begin
        st_q[j]  <= CARD_DOWN;
        sid_q[j] <= layout[j];
      end
      hi_q           <= 4'd0;
      a_idx_q        <= 5'd31;
      b_idx_q        <= 5'd31;
      pause_cnt_q    <= '0;
      cur_pl_q       <= 1'b0;
      p1_score_q     <= 4'd0;
      p2_score_q     <= 4'd0;
      start_turn_q   <= 1'b1;
      blink_q        <= 1'b0;
      rnd_captured_q <= 4'd0;
    end else begin
      for (j=0; j<N_CARDS; j++) st_q[j] <= st_d[j];
      hi_q           <= hi_d;
      a_idx_q        <= a_idx_d;
      b_idx_q        <= b_idx_d;
      pause_cnt_q    <= pause_cnt_d;
      cur_pl_q       <= cur_pl_d;
      p1_score_q     <= p1_score_d;
      p2_score_q     <= p2_score_d;
      start_turn_q   <= start_turn_d;
      blink_q        <= blink_d;
      rnd_captured_q <= rnd_captured_d;
    end
  end

  // Temporales
  logic [3:0] rnda, rndb;        // dos nibbles aleatorios del rnd8_i
  logic [3:0] pick1_temp, pick2_temp;
  logic [3:0] pair_p1, pair_p2;  // picks del auto–par
  logic       pair_valid;
  logic       match_this_cycle;

  assign rnda = rnd8_i[3:0];
  assign rndb = rnd8_i[7:4];

  // ============ Combinacional ============
  always_comb begin
    // Defaults
    for (int i=0; i<N_CARDS; i++) st_d[i] = st_q[i];
    hi_d           = hi_q;
    a_idx_d        = a_idx_q;
    b_idx_d        = b_idx_q;
    pause_cnt_d    = pause_cnt_q;
    cur_pl_d       = cur_pl_q;
    p1_score_d     = p1_score_q;
    p2_score_d     = p2_score_q;
    start_turn_d   = 1'b0;
    blink_d        = blink_q;
    rnd_captured_d = rnd_captured_q;
    match_this_cycle = 1'b0;

    // Picks para flujos:
    // - Manual/auto escalonado (anteriores): usan rnda (1ª) y rnd_captured_q (2ª)
    pick1_temp = pick_down_excl(rnda, 1'b0, 4'h0);
    pick2_temp = pick_down_excl(rnd_captured_q, 1'b1, a_idx_q[3:0]);

    // - Auto–par simultáneo: usa dos nibbles independientes
    pair_p1    = pick_down_excl(rnda, 1'b0, 4'h0);
    pair_p2    = pick_down_excl(rndb, 1'b1, pair_p1);
    pair_valid = (pair_p1 != 4'hF) && (pair_p2 != 4'hF);

    // Navegación con NEXT: saltar a una carta DOWN
    if (btn_next_i) hi_d = next_alive(hi_q);
    if (st_q[hi_q] != CARD_DOWN) hi_d = next_alive(hi_q);

    // --- 1ª carta (manual)
    if (select_first_card_i && st_q[hi_q]==CARD_DOWN) begin
      st_d[hi_q] = CARD_UP;
      a_idx_d    = {1'b0, hi_q};
      b_idx_d    = 5'd31;
      rnd_captured_d = rnda; // captura random para 2ª en flujo manual
    end

    // --- 1ª carta (auto, flujo manual en S_ONE)
    if (auto_select_first_i && pick1_temp != 4'hF) begin
      st_d[pick1_temp] = CARD_UP;
      a_idx_d          = {1'b0, pick1_temp};
      b_idx_d          = 5'd31;
      hi_d             = pick1_temp;
      rnd_captured_d   = rnda; // captura random para 2ª
    end

    // --- 2ª carta (manual)
    if (select_second_card_i && st_q[hi_q]==CARD_DOWN) begin
      st_d[hi_q] = CARD_UP;
      b_idx_d    = {1'b0, hi_q};
    end

    // --- 2ª carta (auto, flujo manual en S_ONE)
    if (auto_select_second_i && pick2_temp != 4'hF) begin
      st_d[pick2_temp] = CARD_UP;
      b_idx_d          = {1'b0, pick2_temp};
      hi_d             = pick2_temp;
    end

    // --- Auto–PAR (ambas en el mismo ciclo)
    if (auto_select_pair_i && pair_valid) begin
      // Levantar 1ª y 2ª
      st_d[pair_p1] = CARD_UP;
      st_d[pair_p2] = CARD_UP;
      a_idx_d       = {1'b0, pair_p1};
      b_idx_d       = {1'b0, pair_p2};
      hi_d          = pair_p2;
      // Evaluar match inmediato
      if (sid_q[pair_p1] == sid_q[pair_p2]) begin
        st_d[pair_p1] = CARD_MATCH;
        st_d[pair_p2] = CARD_MATCH;
        if (!cur_pl_q) p1_score_d = p1_score_q + 4'd1;
        else           p2_score_d = p2_score_q + 4'd1;
        a_idx_d = 5'd31; b_idx_d = 5'd31;
        match_this_cycle = 1'b1;

        if (!EXTRA_TURN_ON_MATCH) begin
          cur_pl_d     = ~cur_pl_q;
          start_turn_d = 1'b1;
        end
      end
    end

    // --- Match inmediato (rutas escalonadas)
    if ((select_second_card_i && st_q[hi_q]==CARD_DOWN) ||
        (auto_select_second_i && pick2_temp != 4'hF)) begin
      logic [3:0] second_idx;
      second_idx = select_second_card_i ? hi_q : pick2_temp;

      if (a_idx_q < N_CARDS && second_idx < N_CARDS) begin
        if (a_idx_q != 5'd31 && sid_q[a_idx_q[3:0]] == sid_q[second_idx]) begin
          st_d[a_idx_q[3:0]] = CARD_MATCH;
          st_d[second_idx]   = CARD_MATCH;
          if (!cur_pl_q) p1_score_d = p1_score_q + 4'd1;
          else           p2_score_d = p2_score_q + 4'd1;
          a_idx_d = 5'd31; b_idx_d = 5'd31;
          match_this_cycle = 1'b1;

          hi_d = next_alive(second_idx);
          if (!EXTRA_TURN_ON_MATCH) begin
            cur_pl_d     = ~cur_pl_q;
            start_turn_d = 1'b1;
          end
        end else begin
          b_idx_d = {1'b0, second_idx};
        end
      end
    end

    // Pausa por fallo
    if (start_pause_i) begin
      pause_cnt_d = (REVEAL_PAUSE_TICKS==0) ? 8'd1 : REVEAL_PAUSE_TICKS[7:0];
    end
    if (pause_cnt_q != 0 && tick_fast_i) pause_cnt_d = pause_cnt_q - 8'd1;

    // Fin de turno por fallo
    if (end_turn_i) begin
      if (a_idx_q != 5'd31) st_d[a_idx_q[3:0]] = CARD_DOWN;
      if (b_idx_q != 5'd31) st_d[b_idx_q[3:0]] = CARD_DOWN;
      a_idx_d      = 5'd31; b_idx_d = 5'd31;
      hi_d         = next_alive(hi_q);
      cur_pl_d     = ~cur_pl_q;
      start_turn_d = 1'b1;
    end

    // Blink 1 Hz para displays
    if (tick_blink_i) blink_d = ~blink_q;
  end

  // ============ Señales a FSM ============

  // ¿2ª manual válida?
  assign manual_pick2_valid_o =
      (st_q[hi_q] == CARD_DOWN) &&      // solo DOWN
      (a_idx_q != 5'd31) &&             // debe existir 1ª carta
      (hi_q != a_idx_q[3:0]);           // distinta a la 1ª

  // Predicción de match para gating/transiciones (incluye auto–PAR)
  logic [3:0] temp_second_idx; logic valid_match_check;
  always_comb begin
    temp_second_idx   = 4'hF; 
    valid_match_check = 1'b0;

    if (select_second_card_i && st_q[hi_q]==CARD_DOWN && hi_q < N_CARDS) begin
      temp_second_idx   = hi_q; 
      valid_match_check = 1'b1;
    end else if (auto_select_second_i && pick2_temp != 4'hF && pick2_temp < N_CARDS) begin
      temp_second_idx   = pick2_temp; 
      valid_match_check = 1'b1;
    end else if (auto_select_pair_i && pair_valid) begin
      temp_second_idx   = pair_p2;     // 2ª del par
      valid_match_check = 1'b1;
    end
  end

  assign cards_match_o = (valid_match_check && a_idx_q != 5'd31 && a_idx_q < N_CARDS) ?
                         (sid_q[a_idx_q[3:0]] == sid_q[temp_second_idx]) :
                         // Para el caso de auto–PAR, a_idx_q aún podría ser 31 al comienzo del ciclo;
                         // entonces comparamos directamente pair_p1 vs pair_p2.
                         (auto_select_pair_i && pair_valid ? (sid_q[pair_p1] == sid_q[pair_p2]) : 1'b0);

  assign pause_done_o      = (pause_cnt_q == 8'd1) && tick_fast_i;
  assign match_happened_o  = match_this_cycle;

  // Auto-picks válidos (flujos escalonados)
  assign auto_pick1_valid_o = (pick_down_excl(rnda, 1'b0, 4'h0) != 4'hF);
  assign auto_pick2_valid_o = (pick_down_excl(rnd_captured_q, 1'b1, a_idx_q[3:0]) != 4'hF);

  // ============ Salidas del juego ============
  generate genvar g;
    for (g=0; g<N_CARDS; g++) begin : G_OUTS
      assign state[g]     = st_q[g];
      assign symbol_id[g] = sid_q[g];
    end
  endgenerate

  assign highlight_idx = hi_q;
  assign led_p1_o      = (cur_pl_q == 1'b0);
  assign led_p2_o      = (cur_pl_q == 1'b1);
  assign start_turn_o  = start_turn_q;
  assign p1_score_o    = p1_score_q;
  assign p2_score_o    = p2_score_q;

  // Fin de juego y ganador
  logic [4:0] pairs_done;
  assign pairs_done  = p1_score_q + p2_score_q;
  assign game_over_o = (pairs_done == (N_CARDS/2));
  assign tie_o       = game_over_o && (p1_score_q == p2_score_q);
  assign winner_p2_o = game_over_o && !tie_o && (p2_score_q > p1_score_q);

  // Displays P1/P2
  logic [6:0] seg_p1_fix, seg_p2_fix, seg_off;
  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u_bcd_p1 (.bcd(p1_score_q[3:0]), .seg(seg_p1_fix));
  bcd7seg #(.ACTIVE_LOW(1), .M0(6), .M1(5), .M2(4), .M3(3), .M4(2), .M5(1), .M6(0))
  u_bcd_p2 (.bcd(p2_score_q[3:0]), .seg(seg_p2_fix));

  assign seg_off = (DISP_ACTIVE_LOW) ? 7'b111_1111 : 7'b000_0000;

  always_comb begin
    seg_p1_o = seg_p1_fix;
    seg_p2_o = seg_p2_fix;
    if (cur_pl_q == 1'b0) begin
      seg_p1_o = (blink_q) ? seg_p1_fix : seg_off;
    end else begin
      seg_p2_o = (blink_q) ? seg_p2_fix : seg_off;
    end
  end

endmodule
