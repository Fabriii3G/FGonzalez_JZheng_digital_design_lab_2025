module fsm_control(
  input  logic        clk,
  input  logic        rst_n,
  
  // Entradas de control
  input  logic        btn_sel_i,
  input  logic        time_up_i,
  input  logic        cards_match_i,
  input  logic        pause_done_i,
  input  logic        auto_pick1_valid_i,
  input  logic        auto_pick2_valid_i,
  input  logic        match_happened_i,
  input  logic        game_over_i,
  input  logic        manual_pick2_valid_i,

  // Salidas de control
  output logic        select_first_card_o,
  output logic        select_second_card_o,
  output logic        auto_select_first_o,    // (se mantiene para flujo manual S_ONE)
  output logic        auto_select_second_o,   // (se mantiene para flujo manual S_ONE)
  output logic        auto_select_pair_o,     // <<< NUEVO: auto–par en el mismo ciclo
  output logic        match_found_o,
  output logic        start_pause_o,
  output logic        end_turn_o,
  output logic        extra_turn_o,
  output logic        restart_timer_o,
  
  // Estado actual (para debug/display)
  output logic [1:0]  current_state_o
);

  localparam logic [1:0] S_IDLE  = 2'd0;
  localparam logic [1:0] S_ONE   = 2'd1; 
  localparam logic [1:0] S_PAUSE = 2'd2;
  localparam logic [1:0] S_OVER  = 2'd3;

  logic [1:0] state, next_state;

  // --- Flanco de subida de time_up para no perder eventos ---
  logic time_up_q, time_up_edge;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) time_up_q <= 1'b0;
    else        time_up_q <= time_up_i;
  end
  assign time_up_edge = time_up_i & ~time_up_q;

  // Estado
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S_IDLE;
    else        state <= next_state;
  end

  // Próximo estado
  always_comb begin
    next_state = state;
    unique case (state)
      S_IDLE: begin
        if (game_over_i) begin
          next_state = S_OVER;
        end else if (time_up_edge) begin
          // Se ordena el auto–par; el datapath calculará cards_match_i
          next_state = (cards_match_i) ? S_IDLE : S_PAUSE;
        end else if (btn_sel_i) begin
          next_state = S_ONE; // 1ª manual (datapath valida DOWN)
        end
      end

      S_ONE: begin
        if (game_over_i) begin
          next_state = S_OVER;
        end else if (time_up_edge && auto_pick2_valid_i) begin
          // Flujo manual: si se acaba el tiempo en S_ONE, auto 2ª como antes
          next_state = (cards_match_i) ? S_IDLE : S_PAUSE;
        end else if (btn_sel_i && manual_pick2_valid_i) begin
          next_state = (cards_match_i) ? S_IDLE : S_PAUSE;
        end else if (match_happened_i) begin
          next_state = S_IDLE; // seguridad
        end
      end

      S_PAUSE: begin
        if (game_over_i) begin
          next_state = S_OVER;
        end else if (pause_done_i) begin
          next_state = S_IDLE;
        end
      end

      S_OVER: begin
        next_state = S_OVER;
      end
    endcase
  end

  // Salidas
  always_comb begin
    select_first_card_o  = 1'b0;
    select_second_card_o = 1'b0;
    auto_select_first_o  = 1'b0;
    auto_select_second_o = 1'b0;
    auto_select_pair_o   = 1'b0;   // <<< NUEVO
    match_found_o        = 1'b0;
    start_pause_o        = 1'b0;
    end_turn_o           = 1'b0;
    extra_turn_o         = 1'b0;
    restart_timer_o      = 1'b0;

    if (state != S_OVER) begin
      unique case (state)
        S_IDLE: begin
          if (time_up_edge) begin
            // Ordena seleccionar 2 cartas en el mismo ciclo
            auto_select_pair_o = 1'b1;
            // Decisión según cards_match_i (combinacional desde datapath)
            if (cards_match_i) begin
              match_found_o   = 1'b1;
              extra_turn_o    = 1'b1; // mismo jugador continúa
              restart_timer_o = 1'b1; // nuevo conteo para el mismo jugador
            end else begin
              start_pause_o = 1'b1;   // se mostrarán 2 cartas y luego se esconderán
            end
          end else if (btn_sel_i) begin
            select_first_card_o = 1'b1;
          end
        end

        S_ONE: begin
          // Flujo manual intacto
          if (time_up_edge && auto_pick2_valid_i) begin
            auto_select_second_o = 1'b1;
          end else if (btn_sel_i && manual_pick2_valid_i) begin
            select_second_card_o = 1'b1;
          end

          if ((time_up_edge && auto_pick2_valid_i) || (btn_sel_i && manual_pick2_valid_i)) begin
            if (cards_match_i) begin
              match_found_o   = 1'b1;
              extra_turn_o    = 1'b1;
              restart_timer_o = 1'b1;
            end else begin
              start_pause_o = 1'b1;
            end
          end
        end

        S_PAUSE: begin
          if (pause_done_i) begin
            end_turn_o = 1'b1;
          end
        end
      endcase
    end
  end

  assign current_state_o = state;

endmodule
