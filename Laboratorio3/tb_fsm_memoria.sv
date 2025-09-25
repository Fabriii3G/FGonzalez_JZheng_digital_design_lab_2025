// tb_fsm_memoria.sv (v2: sin "disable fork", compatible con ModelSim/Questa 20.1)
`timescale 1ns/1ps

module tb_fsm_memoria;
  // ---------------------------
  // Señales hacia la FSM
  // ---------------------------
  logic clk = 0;
  logic rst = 1;
  logic btn_ok = 0;
  logic timeout_15s = 0;

  // Salidas que verificamos
  logic timer_load, timer_en;
  logic open_en;
  logic [3:0] open_idx, highlight_idx;

  // DUT
  fsm_memoria dut (
    .clk, .rst,
    .btn_ok, .timeout_15s,
    .timer_load, .timer_en,
    .open_en, .open_idx, .highlight_idx
  );

  // Reloj 100 MHz
  always #5 clk = ~clk;

  // -------------------------------------
  // Enum local que replica la de la FSM
  // -------------------------------------
  typedef enum logic [3:0] {
    S_RESET, S_TURN_START, S_WAIT_SEL1, S_REVEAL1,
    S_WAIT_SEL2, S_REVEAL2, S_CHECK_PAIR, S_KEEP_TURN,
    S_SWITCH_TURN, S_CHECK_WIN, S_TIMEOUT_AUTO, S_GAME_END
  } state_e;

  // Acceso directo al estado interno (jerárquico)
  // Si no te gusta jerarquía, te paso versión con puerto state_out.
  function state_e ST(); return state_e'(dut.st); endfunction

  // -------------------------------------
  // Estímulos
  // -------------------------------------
  initial begin
    // Reset sincrónico breve
    repeat (4) @(posedge clk);
    rst = 0;

    // Espera a WAIT_SEL1 (tras TURN_START)
    wait (ST()==S_WAIT_SEL1);

    // Click 1 -> REVEAL1
    pulse_btn();
    // Espera a WAIT_SEL2
    wait (ST()==S_WAIT_SEL2);

    // Click 2 -> REVEAL2
    pulse_btn();

    // La FSM debe pasar por CHECK_PAIR -> SWITCH_TURN -> CHECK_WIN -> TURN_START
    wait (ST()==S_TURN_START);

    // Caso timeout: en WAIT_SEL1, asertar timeout_15s
    wait (ST()==S_WAIT_SEL1);
    pulse_timeout();

    // Debe ir a S_TIMEOUT_AUTO -> S_SWITCH_TURN -> S_CHECK_WIN -> S_TURN_START
    wait (ST()==S_TURN_START);

    // Fin con un respiro
    repeat (10) @(posedge clk);
    $display("[TB] Finalizado OK");
    $finish;
  end

  task pulse_btn();
    begin
      @(posedge clk); btn_ok <= 1;
      @(posedge clk); btn_ok <= 0;
    end
  endtask

  task pulse_timeout();
    begin
      @(posedge clk); timeout_15s <= 1;
      @(posedge clk); timeout_15s <= 0;
    end
  endtask

  // -------------------------------------
  // Assertions SVA (propiedades clave)
  // -------------------------------------

  // 1) Tras quitar reset, en <=10 ciclos debe verse TURN_START con carga/habilitación del timer
  property p_reset_to_turnstart;
    @(posedge clk) disable iff (rst)
      1'b1 |-> ##[1:10] (ST()==S_TURN_START && timer_load && timer_en);
  endproperty
  a_reset_to_turnstart: assert property (p_reset_to_turnstart)
    else $error("No se cargó/habilitó timer al inicio del turno.");

  // 2) En WAIT_SEL1, un btn_ok lleva a REVEAL1 y open_en se activa ese ciclo
  property p_sel1_to_reveal1;
    @(posedge clk) (ST()==S_WAIT_SEL1 && btn_ok) |=> (ST()==S_REVEAL1 && open_en);
  endproperty
  a_sel1_to_reveal1: assert property (p_sel1_to_reveal1)
    else $error("Click en WAIT_SEL1 no abrió carta 1.");

  // 3) En WAIT_SEL2, un btn_ok lleva a REVEAL2 y open_en se activa
  property p_sel2_to_reveal2;
    @(posedge clk) (ST()==S_WAIT_SEL2 && btn_ok) |=> (ST()==S_REVEAL2 && open_en);
  endproperty
  a_sel2_to_reveal2: assert property (p_sel2_to_reveal2)
    else $error("Click en WAIT_SEL2 no abrió carta 2.");

  // 4) Secuencia tras REVEAL2
  property p_seq_after_reveal2;
    @(posedge clk) (ST()==S_REVEAL2) |=> (ST()==S_CHECK_PAIR) ##1 (ST()==S_SWITCH_TURN)
                                   ##1 (ST()==S_CHECK_WIN)   ##1 (ST()==S_TURN_START);
  endproperty
  a_seq_after_reveal2: assert property (p_seq_after_reveal2)
    else $error("Secuencia posterior a REVEAL2 incorrecta.");

  // 5) Timeout en WAIT_SEL1 lleva a TIMEOUT_AUTO y luego a SWITCH_TURN
  property p_timeout_path;
    @(posedge clk) (ST()==S_WAIT_SEL1 && timeout_15s) |=> (ST()==S_TIMEOUT_AUTO) ##1 (ST()==S_SWITCH_TURN);
  endproperty
  a_timeout_path: assert property (p_timeout_path)
    else $error("Ruta de timeout 15s incorrecta.");

  // 6) timer_en debe estar activo durante las esperas y revelados (según diseño del avance)
  property p_timer_en_when_waiting;
    @(posedge clk) (ST()==S_WAIT_SEL1 || ST()==S_WAIT_SEL2 || ST()==S_REVEAL1 || ST()==S_REVEAL2) |-> timer_en;
  endproperty
  a_timer_en_when_waiting: assert property (p_timer_en_when_waiting)
    else $error("timer_en debería estar activo en WAIT/REVEAL.");

  // 7) Liveness simple: debe verse al menos un open_en en <= 2000 ciclos
  initial begin
    int cycles = 0;
    bit saw_open = 0;
    while (cycles < 2000) begin
      @(posedge clk);
      cycles++;
      if (open_en) saw_open = 1;
    end
    if (!saw_open) $error("Nunca se abrió una carta (open_en) en la ventana de prueba.");
  end

endmodule
