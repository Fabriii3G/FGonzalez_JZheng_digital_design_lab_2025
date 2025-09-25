// fsm_memoria.sv (fix: sin inicializaciones en declaración para evitar constant drivers)
import lab3_params::*;

module fsm_memoria (
  input  logic clk, rst,
  input  logic btn_ok,
  input  logic timeout_15s,
  output logic timer_load, timer_en,
  output logic open_en,
  output logic [3:0] open_idx,
  output logic [3:0] highlight_idx
);
  typedef enum logic [3:0] {
    S_RESET, S_TURN_START, S_WAIT_SEL1, S_REVEAL1,
    S_WAIT_SEL2, S_REVEAL2, S_CHECK_PAIR, S_KEEP_TURN,
    S_SWITCH_TURN, S_CHECK_WIN, S_TIMEOUT_AUTO, S_GAME_END
  } state_e;

  state_e st, nx;

  // ¡OJO! Sin "= 0" ni "= 1" aquí:
  logic [3:0] sel1; 
  logic [3:0] sel2;
  logic       turn;

  // cursor demo para resaltar/seleccionar
  logic [3:0] cursor;

  // --- Cursor demo
  always_ff @(posedge clk) begin
    if (rst) cursor <= 4'd0;
    else if (btn_ok) cursor <= cursor + 4'd1;
  end

  // --- Registro de estado
  always_ff @(posedge clk) begin
    if (rst) begin
      st   <= S_RESET;
      sel1 <= 4'd0;     // asignaciones solo aquí (un único driver)
      sel2 <= 4'd1;
      turn <= 1'b0;
    end else begin
      st <= nx;
      // captura de selecciones demo
      if (st==S_WAIT_SEL1 && btn_ok) sel1 <= cursor;
      if (st==S_WAIT_SEL2 && btn_ok) sel2 <= cursor;
      if (st==S_SWITCH_TURN)         turn <= ~turn;
    end
  end

  // --- Salidas (Moore)
  always_comb begin
    timer_load     = 1'b0;
    timer_en       = 1'b0;
    open_en        = 1'b0;
    open_idx       = 4'd0;
    highlight_idx  = cursor;

    unique case (st)
      S_RESET: begin end
      S_TURN_START: begin
        timer_load = 1'b1;
        timer_en   = 1'b1;
      end
      S_WAIT_SEL1: begin
        timer_en   = 1'b1;
      end
      S_REVEAL1: begin
        open_en  = 1'b1;
        open_idx = sel1;
        timer_en = 1'b1;
      end
      S_WAIT_SEL2: begin
        timer_en = 1'b1;
      end
      S_REVEAL2: begin
        open_en  = 1'b1;
        open_idx = sel2;
        timer_en = 1'b1;
      end
      default: begin end
    endcase
  end

  // --- Próximo estado
  always_comb begin
    nx = st;
    unique case (st)
      S_RESET:        nx = S_TURN_START;
      S_TURN_START:   nx = S_WAIT_SEL1;

      S_WAIT_SEL1: begin
        if (btn_ok)           nx = S_REVEAL1;
        else if (timeout_15s) nx = S_TIMEOUT_AUTO;
      end

      S_REVEAL1:      nx = S_WAIT_SEL2;

      S_WAIT_SEL2: begin
        if (btn_ok)           nx = S_REVEAL2;
        else if (timeout_15s) nx = S_TIMEOUT_AUTO;
      end

      S_REVEAL2:      nx = S_CHECK_PAIR;
      S_CHECK_PAIR:   nx = S_SWITCH_TURN;   // simplificado para el avance
      S_SWITCH_TURN:  nx = S_CHECK_WIN;
      S_CHECK_WIN:    nx = S_TURN_START;
      S_TIMEOUT_AUTO: nx = S_SWITCH_TURN;
      S_GAME_END:     nx = S_GAME_END;
      default:        nx = S_RESET;
    endcase
  end
endmodule
