import lab3_params::*;

module fsm_memoria #(
  parameter int N_CARDS = 16,
  parameter int REVEAL_PAUSE_TICKS = 12,
  parameter bit EXTRA_TURN_ON_MATCH = 1'b1,
  parameter bit DISP_ACTIVE_LOW     = 1'b1
)(
  input  logic                 clk,
  input  logic                 rst_n,
  input  logic                 btn_next_i,
  input  logic                 btn_sel_i,
  input  logic                 tick_fast_i,
  input  logic                 tick_blink_i,
  input  logic                 time_up_i,
  input  logic [3:0]           rnd4_i,
  input  logic [3:0]           layout [N_CARDS-1:0],
  output card_state_e          state [N_CARDS-1:0],
  output logic [3:0]           symbol_id[N_CARDS-1:0],
  output logic [3:0]           highlight_idx,
  output logic                 led_p1_o,
  output logic                 led_p2_o,
  output logic                 start_turn_o,
  output logic                 restart_timer_o,
  output logic [3:0]           p1_score_o,
  output logic [3:0]           p2_score_o,
  output logic [6:0]           seg_p1_o,
  output logic [6:0]           seg_p2_o,
  output logic                 game_over_o,
  output logic                 winner_p2_o,
  output logic                 tie_o,
  // --- NEW: pausa del timer cuando la FSM está en PAUSE/OVER
  output logic                 pause_timer_o
);

  // Señales entre FSM y Datapath
  logic select_first_card;
  logic select_second_card;
  logic auto_select_first;
  logic auto_select_second;
  logic match_found;
  logic start_pause;
  logic end_turn;
  logic extra_turn;
  logic cards_match;
  logic pause_done;
  logic auto_pick1_valid;
  logic auto_pick2_valid;
  logic manual_pick2_valid;
  logic match_happened;
  logic [1:0] fsm_state;

  // Datapath
  game_datapath #(
    .N_CARDS            (N_CARDS),
    .REVEAL_PAUSE_TICKS (REVEAL_PAUSE_TICKS),
    .EXTRA_TURN_ON_MATCH(EXTRA_TURN_ON_MATCH),
    .DISP_ACTIVE_LOW    (DISP_ACTIVE_LOW)
  ) u_datapath (
    .clk                  (clk),
    .rst_n                (rst_n),
    .select_first_card_i  (select_first_card),
    .select_second_card_i (select_second_card),
    .auto_select_first_i  (auto_select_first),
    .auto_select_second_i (auto_select_second),
    .match_found_i        (match_found),
    .start_pause_i        (start_pause),
    .end_turn_i           (end_turn),
    .extra_turn_i         (extra_turn),
    .btn_next_i           (btn_next_i),
    .tick_fast_i          (tick_fast_i),
    .tick_blink_i         (tick_blink_i),
    .rnd4_i               (rnd4_i),
    .layout               (layout),
    .cards_match_o        (cards_match),
    .pause_done_o         (pause_done),
    .auto_pick1_valid_o   (auto_pick1_valid),
    .auto_pick2_valid_o   (auto_pick2_valid),
    .match_happened_o     (match_happened),
    .manual_pick2_valid_o (manual_pick2_valid),
    .state                (state),
    .symbol_id            (symbol_id),
    .highlight_idx        (highlight_idx),
    .led_p1_o             (led_p1_o),
    .led_p2_o             (led_p2_o),
    .start_turn_o         (start_turn_o),
    .p1_score_o           (p1_score_o),
    .p2_score_o           (p2_score_o),
    .seg_p1_o             (seg_p1_o),
    .seg_p2_o             (seg_p2_o),
    .game_over_o          (game_over_o),
    .winner_p2_o          (winner_p2_o),
    .tie_o                (tie_o)
  );

  // FSM de control (ya expone current_state_o=fsm_state)
  fsm_control u_fsm_ctrl (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .btn_sel_i             (btn_sel_i),
    .time_up_i             (time_up_i),
    .cards_match_i         (cards_match),
    .pause_done_i          (pause_done),
    .auto_pick1_valid_i    (auto_pick1_valid),
    .auto_pick2_valid_i    (auto_pick2_valid),
    .match_happened_i      (match_happened),
    .game_over_i           (game_over_o),
    .manual_pick2_valid_i  (manual_pick2_valid),
    .select_first_card_o   (select_first_card),
    .select_second_card_o  (select_second_card),
    .auto_select_first_o   (auto_select_first),
    .auto_select_second_o  (auto_select_second),
    .match_found_o         (match_found),
    .start_pause_o         (start_pause),
    .end_turn_o            (end_turn),
    .extra_turn_o          (extra_turn),
    .restart_timer_o       (restart_timer_o),
    .current_state_o       (fsm_state)
  );

  // Códigos de estado (coinciden con fsm_control)
  localparam logic [1:0] S_IDLE  = 2'd0;
  localparam logic [1:0] S_ONE   = 2'd1;
  localparam logic [1:0] S_PAUSE = 2'd2;
  localparam logic [1:0] S_OVER  = 2'd3;

  // --- NEW: pausar timer en PAUSE y OVER ---
  assign pause_timer_o = (fsm_state == S_PAUSE) || (fsm_state == S_OVER);

endmodule
