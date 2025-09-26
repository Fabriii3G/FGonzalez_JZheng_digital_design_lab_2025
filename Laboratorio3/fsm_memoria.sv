// fsm_memoria.sv — Memoria 4x4, 2 jugadores, NEXT/SEL, timeout con jugada al azar,
// turno extra en match y reinicio de temporizador al acertar o al auto-jugar.
// Compatible Quartus 20.1.
import lab3_params::*; // card_state_e: {CARD_DOWN, CARD_UP, CARD_MATCH}

module fsm_memoria #(
  parameter int N_CARDS = 16,
  parameter int REVEAL_PAUSE_TICKS = 12,    // ~600 ms si tick_fast_i=20 Hz
  parameter bit EXTRA_TURN_ON_MATCH = 1'b1
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // Botones (ya one-pulse y enmascarados en el top)
  input  logic                 btn_next_i,
  input  logic                 btn_sel_i,

  // Tick "rápido" para la pausa tras mismatch
  input  logic                 tick_fast_i,

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

  // Indicadores y control de turno
  output logic                 led_p1_o,
  output logic                 led_p2_o,
  output logic                 start_turn_o,    // pulso 1 ciclo al iniciar turno (cambio de jugador)
  output logic                 restart_timer_o, // pulso 1 ciclo para reiniciar a 15s

  // (opcionales) marcadores
  output logic [3:0]           p1_score_o,
  output logic [3:0]           p2_score_o
);

  // ---------------- Registros base ----------------
  card_state_e st_q [N_CARDS], st_d [N_CARDS];
  logic [3:0]  sid_q[N_CARDS];

  logic [3:0]  hi_q, hi_d;
  logic [3:0]  a_idx_q, a_idx_d;
  logic [3:0]  b_idx_q, b_idx_d;

  typedef enum logic [1:0] {S_IDLE, S_ONE, S_PAUSE} fsm_e;
  fsm_e ps_q, ps_d;

  logic [7:0]  pause_cnt_q, pause_cnt_d;

  // Jugadores / marcador / pulsos
  logic        cur_pl_q, cur_pl_d;         // 0 = P1, 1 = P2
  logic [3:0]  p1_score_q, p1_score_d;
  logic [3:0]  p2_score_q, p2_score_d;
  logic        start_turn_q, start_turn_d; // pulso
  logic        restart_timer_q, restart_timer_d; // pulso

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

  // Pick aleatorio: desde "start", busca una carta válida
  function automatic logic [3:0] pick_down_excl(
      input logic [3:0] start,
      input logic       use_excl,
      input logic [3:0] excl_idx
  );
    logic [3:0] k;
    pick_down_excl = 4'hF; // no encontrada
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

  // ---------------- Reset / Carga inicial ----------------
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

      cur_pl_q        <= 1'b0;     // empieza P1
      p1_score_q      <= 4'd0;
      p2_score_q      <= 4'd0;
      start_turn_q    <= 1'b1;     // primer turno
      restart_timer_q <= 1'b0;
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
    end
  end

  // ---------------- Next-state ----------------
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

    // navegación normal
    if (btn_next_i) hi_d = next_alive(hi_q);

    // ---------- TIMEOUT: auto-jugada ----------
    if (time_up_i) begin
      unique case (ps_q)
        S_IDLE: begin
          // Elegir UNA carta al azar (DOWN y no MATCH)
          logic [3:0] pick1;
          pick1 = pick_down_excl(rnd4_i, /*use_excl*/ 1'b0, 4'h0);
          if (pick1 != 4'hF) begin
            st_d[pick1] = CARD_UP;
            a_idx_d     = pick1;
            b_idx_d     = 4'hF;
            hi_d        = pick1;
            ps_d        = S_ONE;
            restart_timer_d = 1'b1; // reinicia tiempo para que el jugador tenga margen a elegir la 2da
          end
        end

        S_ONE: begin
          // Elegir SEGUNDA carta al azar (DOWN, no MATCH, distinta de a_idx_q)
          logic [3:0] pick2;
          pick2 = pick_down_excl(rnd4_i, /*use_excl*/ 1'b1, a_idx_q);
          if (pick2 != 4'hF) begin
            st_d[pick2] = CARD_UP;
            b_idx_d     = pick2;
            hi_d        = pick2;

            // Resolver inmediatamente como si hubiera presionado SEL
            if (sid_q[a_idx_q] == sid_q[pick2]) begin
              st_d[a_idx_q] = CARD_MATCH;
              st_d[pick2]   = CARD_MATCH;
              if (cur_pl_q==1'b0) p1_score_d = p1_score_q + 4'd1;
              else                 p2_score_d = p2_score_q + 4'd1;

              a_idx_d = 4'hF; b_idx_d = 4'hF;
              ps_d    = S_IDLE;

              // Turno extra habilitado → se queda el mismo jugador
              // y **reinicia el temporizador** (regla nueva)
              restart_timer_d = 1'b1;

              if (!EXTRA_TURN_ON_MATCH) begin
                cur_pl_d     = ~cur_pl_q;   // si no hubiera extra-turn
                start_turn_d = 1'b1;
              end
            end else begin
              // mismatch → pausa y luego cambio de jugador (como siempre)
              ps_d        = S_PAUSE;
              pause_cnt_d = (REVEAL_PAUSE_TICKS==0) ? 8'd1
                                                    : REVEAL_PAUSE_TICKS[7:0];
            end
          end
        end

        default: ; // en S_PAUSE ignoramos timeout (ya está en curso la animación)
      endcase
    end

    // ---------- Flujo normal por botones ----------
    unique case (ps_q)
      S_IDLE: begin
        if (st_q[hi_q]==CARD_MATCH) hi_d = next_alive(hi_q);

        if (btn_sel_i) begin
          if (st_q[hi_q]==CARD_DOWN) begin
            st_d[hi_q] = CARD_UP;
            a_idx_d    = hi_q;
            b_idx_d    = 4'hF;
            ps_d       = S_ONE;
          end
        end
      end

      S_ONE: begin
        if (btn_sel_i) begin
          if (st_q[hi_q]==CARD_DOWN) begin
            st_d[hi_q] = CARD_UP;
            b_idx_d    = hi_q;

            if (sid_q[a_idx_q] == sid_q[hi_q]) begin
              st_d[a_idx_q] = CARD_MATCH;
              st_d[hi_q]    = CARD_MATCH;
              if (cur_pl_q==1'b0) p1_score_d = p1_score_q + 4'd1;
              else                 p2_score_d = p2_score_q + 4'd1;

              a_idx_d = 4'hF; b_idx_d = 4'hF;
              ps_d    = S_IDLE;

              // Turno extra + reiniciar temporizador por acierto
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
      end

      S_PAUSE: begin
        if (pause_cnt_q != 0 && tick_fast_i) begin
          pause_cnt_d = pause_cnt_q - 8'd1;
        end

        if (pause_cnt_q == 8'd1 && tick_fast_i) begin
          if (a_idx_q != 4'hF) st_d[a_idx_q] = CARD_DOWN;
          if (b_idx_q != 4'hF) st_d[b_idx_q] = CARD_DOWN;
          a_idx_d = 4'hF; b_idx_d = 4'hF;

          hi_d        = next_alive(hi_q);
          ps_d        = S_IDLE;
          cur_pl_d    = ~cur_pl_q;   // cambio de jugador por fallo
          start_turn_d= 1'b1;        // reinicio de timer por cambio de turno
        end
      end
    endcase
  end

  // ---------------- Salidas ----------------
  generate
    genvar g;
    for (g=0; g<N_CARDS; g++) begin : G_OUTS
      assign state[g]     = st_q[g];
      assign symbol_id[g] = sid_q[g];
    end
  endgenerate

  assign highlight_idx   = hi_q;
  assign led_p1_o        = (cur_pl_q==1'b0);
  assign led_p2_o        = (cur_pl_q==1'b1);
  assign start_turn_o    = start_turn_q;
  assign restart_timer_o = restart_timer_q;
  assign p1_score_o      = p1_score_q;
  assign p2_score_o      = p2_score_q;

endmodule
