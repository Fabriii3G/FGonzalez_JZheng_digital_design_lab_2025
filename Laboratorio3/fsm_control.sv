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
  input  logic        manual_pick2_valid_i,   // <<< NUEVA: 2ª manual válida
  
  // Salidas de control
  output logic        select_first_card_o,
  output logic        select_second_card_o,
  output logic        auto_select_first_o,
  output logic        auto_select_second_o,
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
        end else if (time_up_i && auto_pick1_valid_i) begin
          next_state = S_ONE;
        end else if (btn_sel_i) begin
          next_state = S_ONE; // 1ª manual (datapath valida DOWN)
        end
      end

      S_ONE: begin
        if (game_over_i) begin
          next_state = S_OVER;
        end else if (time_up_i && auto_pick2_valid_i) begin
          next_state = (cards_match_i) ? S_IDLE : S_PAUSE;
        end else if (btn_sel_i && manual_pick2_valid_i) begin
          // SOLO si la 2ª manual es válida (DOWN y distinta)
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
    match_found_o        = 1'b0;
    start_pause_o        = 1'b0;
    end_turn_o           = 1'b0;
    extra_turn_o         = 1'b0;
    restart_timer_o      = 1'b0;

    if (state != S_OVER) begin
      case (state)
        S_IDLE: begin
          if (time_up_i && auto_pick1_valid_i) begin
            auto_select_first_o = 1'b1;
            restart_timer_o     = 1'b1;
          end else if (btn_sel_i) begin
            select_first_card_o = 1'b1;
          end
        end

        S_ONE: begin
          if (time_up_i && auto_pick2_valid_i) begin
            auto_select_second_o = 1'b1;
            // La transición decide match/fallo
          end else if (btn_sel_i && manual_pick2_valid_i) begin
            select_second_card_o = 1'b1;
          end

          if ((time_up_i && auto_pick2_valid_i) || (btn_sel_i && manual_pick2_valid_i)) begin
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

        default: ;
      endcase
    end
  end

  assign current_state_o = state;

endmodule
