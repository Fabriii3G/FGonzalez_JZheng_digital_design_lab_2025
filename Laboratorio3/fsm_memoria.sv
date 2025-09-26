// fsm_memoria.sv — navegación con NEXT y selección con SEL (compatible Quartus 20.1)
import lab3_params::*; // card_state_e: {CARD_DOWN, CARD_UP, CARD_MATCH}

module fsm_memoria #(
  parameter int N_CARDS = 16,
  parameter int REVEAL_PAUSE_TICKS = 30,     // ~0.6s si tick_fast_i=20Hz
  parameter bit EXTRA_TURN_ON_MATCH = 1'b1
)(
  input  logic                 clk,
  input  logic                 rst_n,

  // Botones ya “one-pulse”
  input  logic                 btn_next_i,   // avanza highlight (salta MATCH)
  input  logic                 btn_sel_i,    // selecciona carta

  // Reloj de pausa (más rápido que 1Hz; p.ej. 20Hz)
  input  logic                 tick_fast_i,

  // Layout de símbolos (dos copias 0..7 barajadas)
  input  logic [3:0]           layout   [N_CARDS-1:0],

  // Salidas a video
  output card_state_e          state    [N_CARDS-1:0],
  output logic         [3:0]   symbol_id[N_CARDS-1:0],
  output logic         [3:0]   highlight_idx
);

  // ------------------------------------------------------------
  // Registros ( *_q ) y siguientes ( *_d )
  // ------------------------------------------------------------
  // Estado de cada carta
  card_state_e st_q [N_CARDS];
  card_state_e st_d [N_CARDS];

  // Símbolo por carta (fijo desde layout)
  logic [3:0] sid_q [N_CARDS];  // solo se carga al reset

  // Highlight
  logic [3:0] hi_q, hi_d;

  // Índices de selección
  logic [3:0] a_idx_q, a_idx_d;   // primera carta levantada
  logic [3:0] b_idx_q, b_idx_d;   // segunda carta levantada

  // FSM principal
  typedef enum logic [1:0] {S_IDLE, S_ONE, S_PAUSE} fsm_e;
  fsm_e ps_q, ps_d;

  // Contador de pausa para mismatch
  logic [7:0] pause_cnt_q, pause_cnt_d;

  // ------------------------------------------------------------
  // Funciones helper
  // ------------------------------------------------------------
  function automatic logic [3:0] next_alive(input logic [3:0] cur);
    logic [3:0] k;
    next_alive = cur;
    for (int step=1; step<=N_CARDS; step++) begin
      k = (cur + step[3:0]) & 4'hF; // mod 16
      if (st_q[k] != CARD_MATCH) begin
        next_alive = k;
        break;
      end
    end
  endfunction

  // ------------------------------------------------------------
  // Reset / Carga inicial
  // ------------------------------------------------------------
  integer j;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (j=0; j<N_CARDS; j++) begin
        st_q[j]  <= CARD_DOWN;
        sid_q[j] <= layout[j];
      end
      hi_q        <= 4'd0;
      a_idx_q     <= 4'hF;
      b_idx_q     <= 4'hF;
      ps_q        <= S_IDLE;
      pause_cnt_q <= '0;
    end else begin
      // avanzar registros
      for (j=0; j<N_CARDS; j++) st_q[j] <= st_d[j];
      hi_q        <= hi_d;
      a_idx_q     <= a_idx_d;
      b_idx_q     <= b_idx_d;
      ps_q        <= ps_d;
      pause_cnt_q <= pause_cnt_d;
    end
  end

  // ------------------------------------------------------------
  // Combinacional: siguiente estado y acciones
  // ------------------------------------------------------------
  always_comb begin
    // defaults
    for (int i=0; i<N_CARDS; i++) st_d[i] = st_q[i];
    hi_d        = hi_q;
    a_idx_d     = a_idx_q;
    b_idx_d     = b_idx_q;
    ps_d        = ps_q;
    pause_cnt_d = pause_cnt_q;

    // mover highlight con NEXT
    if (btn_next_i) hi_d = next_alive(hi_q);

    unique case (ps_q)
      // -----------------------
      S_IDLE: begin
        // si carta actual está en MATCH, salta a la siguiente viva
        if (st_q[hi_q]==CARD_MATCH) hi_d = next_alive(hi_q);

        if (btn_sel_i) begin
          if (st_q[hi_q]==CARD_DOWN) begin
            st_d[hi_q] = CARD_UP;
            a_idx_d    = hi_q;
            b_idx_d    = 4'hF;
            ps_d       = S_ONE;
          end
          // si estaba UP o MATCH, ignoramos
        end
      end

      // -----------------------
      S_ONE: begin
        if (btn_sel_i) begin
          if (st_q[hi_q]==CARD_DOWN) begin
            st_d[hi_q] = CARD_UP;
            b_idx_d    = hi_q;

            // comparar símbolos
            if (sid_q[a_idx_q] == sid_q[hi_q]) begin
              st_d[a_idx_q] = CARD_MATCH;
              st_d[hi_q]    = CARD_MATCH;
              a_idx_d       = 4'hF;
              b_idx_d       = 4'hF;
              ps_d          = S_IDLE;
              // EXTRA_TURN_ON_MATCH: nos quedamos en hi_d
              // (si no quisieras extra turno, podrías mover hi_d = next_alive(hi_q);)
            end else begin
              // mismatch → mostrar un rato ambas y luego voltearlas
              ps_d        = S_PAUSE;
              pause_cnt_d = (REVEAL_PAUSE_TICKS==0) ? 8'd1 : REVEAL_PAUSE_TICKS[7:0];
            end
          end
        end
      end

      // -----------------------
      S_PAUSE: begin
        if (pause_cnt_q != 0 && tick_fast_i) begin
          pause_cnt_d = pause_cnt_q - 8'd1;
        end

        // cuando termina la pausa, volteamos y regresamos a IDLE
        if (pause_cnt_q == 8'd1 && tick_fast_i) begin
          if (a_idx_q != 4'hF) st_d[a_idx_q] = CARD_DOWN;
          if (b_idx_q != 4'hF) st_d[b_idx_q] = CARD_DOWN;
          a_idx_d = 4'hF;
          b_idx_d = 4'hF;

          hi_d    = next_alive(hi_q);
          ps_d    = S_IDLE;
        end
      end
    endcase
  end

  // ------------------------------------------------------------
  // Salidas
  // ------------------------------------------------------------
  generate
    genvar g;
    for (g=0; g<N_CARDS; g++) begin : G_OUTS
      assign state[g]     = st_q[g];
      assign symbol_id[g] = sid_q[g];
    end
  endgenerate

  assign highlight_idx = hi_q;

endmodule
