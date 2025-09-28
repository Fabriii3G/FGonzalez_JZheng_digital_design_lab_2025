// fsm_control.sv - FSM limpia solo para control de estados
module fsm_control(
  input  logic        clk,
  input  logic        rst_n,
  
  // Entradas de control
  input  logic        btn_sel_i,
  input  logic        time_up_i,
  input  logic        cards_match_i,       // desde datapath
  input  logic        pause_done_i,       // desde datapath
  input  logic        auto_pick1_valid_i, // desde datapath
  input  logic        auto_pick2_valid_i, // desde datapath
  input  logic        match_happened_i,   // nueva: indica que ocurrió un match
  
  // Salidas de control
  output logic        select_first_card_o,
  output logic        select_second_card_o,
  output logic        auto_select_first_o,
  output logic        auto_select_second_o,
  output logic        match_found_o,
  output logic        start_pause_o,
  output logic        end_turn_o,          // cambio de jugador por fallo
  output logic        extra_turn_o,        // turno extra por acierto
  output logic        restart_timer_o,
  
  // Estado actual (para debug/display)
  output logic [1:0]  current_state_o
);

  // Estados simples
  localparam [1:0] S_IDLE  = 2'b00;
  localparam [1:0] S_ONE   = 2'b01; 
  localparam [1:0] S_PAUSE = 2'b10;

  // Registro de estado
  logic [1:0] state, next_state;

  // ================ ESTADO ACTUAL ================
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
      state <= S_IDLE;
    else        
      state <= next_state;
  end

  // ================ PRÓXIMO ESTADO ================
  always_comb begin
    // Defaults
    next_state = state;
    
    case(state)
      S_IDLE: begin
        if (time_up_i && auto_pick1_valid_i) begin
          next_state = S_ONE;  // auto-selección primera carta
        end else if (btn_sel_i) begin
          next_state = S_ONE;  // selección manual primera carta
        end
      end
      
      S_ONE: begin
        if (time_up_i && auto_pick2_valid_i) begin
          if (cards_match_i) 
            next_state = S_IDLE;  // acierto directo
          else 
            next_state = S_PAUSE; // fallo, mostrar cartas
        end else if (btn_sel_i) begin
          if (cards_match_i)
            next_state = S_IDLE;  // acierto directo  
          else
            next_state = S_PAUSE; // fallo, mostrar cartas
        end
        // Si hubo match por otra lógica, también ir a IDLE
        else if (match_happened_i) begin
          next_state = S_IDLE;
        end
      end
      
      S_PAUSE: begin
        if (pause_done_i) begin
          next_state = S_IDLE;
        end
      end
      
      default: next_state = S_IDLE;
    endcase
  end

  // ================ SALIDAS ================
  always_comb begin
    // Defaults
    select_first_card_o  = 1'b0;
    select_second_card_o = 1'b0;
    auto_select_first_o  = 1'b0;
    auto_select_second_o = 1'b0;
    match_found_o        = 1'b0;
    start_pause_o        = 1'b0;
    end_turn_o           = 1'b0;
    extra_turn_o         = 1'b0;
    restart_timer_o      = 1'b0;
    
    case(state)
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
          // La lógica de match se maneja en las transiciones de estado
        end else if (btn_sel_i) begin
          select_second_card_o = 1'b1;
          // La lógica de match se maneja en las transiciones de estado
        end
      end
      
      default: ;
    endcase

    // Salidas basadas en transiciones (no estados)
    if (state == S_ONE) begin
      if ((time_up_i && auto_pick2_valid_i) || btn_sel_i) begin
        if (cards_match_i) begin
          match_found_o   = 1'b1;
          extra_turn_o    = 1'b1;
          restart_timer_o = 1'b1;  // Reiniciar timer por acierto
        end else begin
          start_pause_o = 1'b1;
        end
      end
    end

    // También reiniciar timer si hubo match por la lógica inmediata del datapath
    if (match_happened_i) begin
      restart_timer_o = 1'b1;
    end

    if (state == S_PAUSE && pause_done_i) begin
      end_turn_o = 1'b1;  // cambio de jugador
    end
  end

  // Estado para debug
  assign current_state_o = state;

endmodule 