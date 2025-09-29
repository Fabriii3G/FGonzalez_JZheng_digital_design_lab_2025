// tb_fsm_control.sv — Testbench de transición de estados para fsm_control

`timescale 1ns/1ps

module tb_fsm_control;

  // -------------------- Reloj y reset --------------------
  logic clk;
  logic rst_n;

  localparam real CLK_PERIOD_NS = 10.0;

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2.0) clk = ~clk;
  end

  task automatic apply_reset;
    begin
      rst_n = 1'b0;
      repeat (3) @(posedge clk);
      rst_n = 1'b1;
      @(posedge clk);
    end
  endtask

  // -------------------- Señales hacia el DUT --------------------
  logic btn_sel_i;
  logic time_up_i;
  logic cards_match_i;
  logic pause_done_i;
  logic auto_pick1_valid_i;
  logic auto_pick2_valid_i;
  logic match_happened_i;

  // -------------------- Señales desde el DUT --------------------
  logic select_first_card_o;
  logic select_second_card_o;
  logic auto_select_first_o;
  logic auto_select_second_o;
  logic match_found_o;
  logic start_pause_o;
  logic end_turn_o;
  logic extra_turn_o;
  logic restart_timer_o;
  logic [1:0] current_state_o;

  // -------------------- Instancia del DUT --------------------
  fsm_control dut (
    .clk                   (clk),
    .rst_n                 (rst_n),
    .btn_sel_i             (btn_sel_i),
    .time_up_i             (time_up_i),
    .cards_match_i         (cards_match_i),
    .pause_done_i          (pause_done_i),
    .auto_pick1_valid_i    (auto_pick1_valid_i),
    .auto_pick2_valid_i    (auto_pick2_valid_i),
    .match_happened_i      (match_happened_i),
    .select_first_card_o   (select_first_card_o),
    .select_second_card_o  (select_second_card_o),
    .auto_select_first_o   (auto_select_first_o),
    .auto_select_second_o  (auto_select_second_o),
    .match_found_o         (match_found_o),
    .start_pause_o         (start_pause_o),
    .end_turn_o            (end_turn_o),
    .extra_turn_o          (extra_turn_o),
    .restart_timer_o       (restart_timer_o),
    .current_state_o       (current_state_o)
  );

  // -------------------- Helpers --------------------
  // Codificación conocida de estados en fsm_control
  localparam [1:0] S_IDLE  = 2'b00;
  localparam [1:0] S_ONE   = 2'b01;
  localparam [1:0] S_PAUSE = 2'b10;

  function automatic string state_to_str(input logic [1:0] s);
    case (s)
      S_IDLE:  state_to_str = "S_IDLE";
      S_ONE:   state_to_str = "S_ONE";
      S_PAUSE: state_to_str = "S_PAUSE";
      default: state_to_str = "UNKNOWN";
    endcase
  endfunction

  task automatic expect_state(input logic [1:0] expected, input string msg="");
    begin
      if (current_state_o !== expected) begin
        $error("[FALLÓ] Estado esperado=%s, observado=%s. %s",
               state_to_str(expected), state_to_str(current_state_o), msg);
      end else begin
        $display("[%0t ns] OK estado=%s. %s", $time, state_to_str(current_state_o), msg);
      end
    end
  endtask

  // Pulso de 1 ciclo para una señal
  task automatic pulse_one_cycle(ref logic signal_ref);
    begin
      signal_ref = 1'b1;
      @(posedge clk);
      signal_ref = 1'b0;
    end
  endtask

  // Limpia todas las entradas
  task automatic clear_inputs;
    begin
      btn_sel_i          = 1'b0;
      time_up_i          = 1'b0;
      cards_match_i      = 1'b0;
      pause_done_i       = 1'b0;
      auto_pick1_valid_i = 1'b0;
      auto_pick2_valid_i = 1'b0;
      match_happened_i   = 1'b0;
      @(posedge clk);
    end
  endtask

  // -------------------- Escenarios de prueba --------------------
  initial begin
    // Dump para waveform
    $dumpfile("tb_fsm_control.vcd");
    $dumpvars(0, tb_fsm_control);

    clear_inputs();
    apply_reset();

    // Tras reset debería estar en IDLE
    expect_state(S_IDLE, "Tras reset");

    // ------------------------------------------------------------
    // 1) Selección MANUAL: IDLE --btn_sel--> ONE
    // ------------------------------------------------------------
    $display("\n--- Caso 1: Seleccion manual de primera carta ---");
    btn_sel_i = 1'b1; // se evalúa en estado IDLE
    @(posedge clk);
    // En este ciclo, DUT debe poner select_first_card_o=1
    assert(select_first_card_o==1) else $error("Esperaba select_first_card_o=1 en IDLE con btn_sel_i");
    btn_sel_i = 1'b0;

    // En el siguiente ciclo, estado debe cambiar a S_ONE
    @(posedge clk);
    expect_state(S_ONE, "Despues de seleccionar primera carta (manual)");

    // ------------------------------------------------------------
    // 2) Segunda carta MANUAL con MATCH: ONE --btn_sel & cards_match--> IDLE
    // ------------------------------------------------------------
    $display("\n--- Caso 2: Segunda carta manual con MATCH ---");
    cards_match_i = 1'b1;
    btn_sel_i     = 1'b1; // trigger segunda selección
    @(posedge clk);
    // En este mismo ciclo deben levantarse flags de match
    assert(select_second_card_o==1) else $error("Esperaba select_second_card_o=1 al pulsar btn_sel en S_ONE");
    assert(match_found_o==1)        else $error("Esperaba match_found_o=1 con cards_match_i=1");
    assert(extra_turn_o==1)         else $error("Esperaba extra_turn_o=1 con cards_match_i=1");
    assert(restart_timer_o==1)      else $error("Esperaba restart_timer_o=1 con match");
    btn_sel_i     = 1'b0;
    cards_match_i = 1'b0;

    // Avanzar a que el estado retorne a IDLE
    @(posedge clk);
    expect_state(S_IDLE, "Regreso a IDLE tras match manual");

    // ------------------------------------------------------------
    // 3) Segunda carta MANUAL SIN MATCH: ONE --btn_sel & !match--> PAUSE
    // luego pause_done → IDLE con end_turn_o
    // ------------------------------------------------------------
    $display("\n--- Caso 3: Segunda carta manual SIN MATCH y pausa ---");
    // Primero volvemos a S_ONE seleccionando primera carta manual otra vez
    pulse_one_cycle(btn_sel_i);      // IDLE -> ONE
    @(posedge clk);
    expect_state(S_ONE, "Despues de seleccionar primera carta (manual, caso sin match)");

    // Ahora segunda selección manual SIN match
    cards_match_i = 1'b0;
    btn_sel_i     = 1'b1;
    @(posedge clk);
    assert(select_second_card_o==1) else $error("Esperaba select_second_card_o=1 en segunda selección manual");
    assert(start_pause_o==1)        else $error("Esperaba start_pause_o=1 cuando NO hay match");
    btn_sel_i = 1'b0;

    // Siguiente ciclo: debe ir a S_PAUSE
    @(posedge clk);
    expect_state(S_PAUSE, "Entro a PAUSE tras fallo");

    // Señalizar que terminó la pausa
    pause_done_i = 1'b1;
    @(posedge clk);
    // En este ciclo debe activar end_turn_o
    assert(end_turn_o==1) else $error("Esperaba end_turn_o=1 al terminar pausa");
    pause_done_i = 1'b0;

    // Próximo ciclo: regresar a IDLE
    @(posedge clk);
    expect_state(S_IDLE, "Regreso a IDLE tras PAUSE");

    // ------------------------------------------------------------
    // 4) Selección AUTOMÁTICA por timeout: 1.ª carta
    // IDLE --(time_up & auto_pick1_valid)--> ONE
    // ------------------------------------------------------------
    $display("\n--- Caso 4: Seleccion automatica de primera carta por timeout ---");
    time_up_i          = 1'b1;
    auto_pick1_valid_i = 1'b1;
    @(posedge clk);
    assert(auto_select_first_o==1) else $error("Esperaba auto_select_first_o=1 con time_up_i y auto_pick1_valid_i en IDLE");
    assert(restart_timer_o==1)     else $error("Esperaba restart_timer_o=1 al auto-seleccionar primera carta");
    // limpiar
    time_up_i          = 1'b0;
    auto_pick1_valid_i = 1'b0;
    @(posedge clk);
    expect_state(S_ONE, "Despues de auto-seleccion de primera carta");

    // ------------------------------------------------------------
    // 5) Segunda AUTOMÁTICA con MATCH: ONE --(time_up & auto_pick2_valid & cards_match)--> IDLE
    // ------------------------------------------------------------
    $display("\n--- Caso 5: Segunda automatica con MATCH ---");
    time_up_i          = 1'b1;
    auto_pick2_valid_i = 1'b1;
    cards_match_i      = 1'b1;
    @(posedge clk);
    assert(auto_select_second_o==1) else $error("Esperaba auto_select_second_o=1 con time_up_i y auto_pick2_valid_i");
    assert(match_found_o==1)        else $error("Esperaba match_found_o=1 en match automático");
    assert(extra_turn_o==1)         else $error("Esperaba extra_turn_o=1 en match automático");
    assert(restart_timer_o==1)      else $error("Esperaba restart_timer_o=1 en match automático");
    // limpiar
    time_up_i          = 1'b0;
    auto_pick2_valid_i = 1'b0;
    cards_match_i      = 1'b0;

    @(posedge clk);
    expect_state(S_IDLE, "Regreso a IDLE tras match automatico");

    // ------------------------------------------------------------
    // 6) Atajo match_happened_i desde S_ONE: debe volver a IDLE y reiniciar timer
    // ------------------------------------------------------------
    $display("\n--- Caso 6: Atajo match_happened_i ---");
    // Ir a S_ONE (primera carta manual)
    pulse_one_cycle(btn_sel_i);
    @(posedge clk);
    expect_state(S_ONE, "Antes de forzar match_happened_i");

    // Forzar atajo
    match_happened_i = 1'b1;
    @(posedge clk);
    // En este ciclo, el TB espera que restart_timer_o esté alto por la lógica del DUT
    assert(restart_timer_o==1) else $error("Esperaba restart_timer_o=1 cuando match_happened_i=1");
    match_happened_i = 1'b0;

    @(posedge clk);
    expect_state(S_IDLE, "Regreso a IDLE por match_happened_i");

    $display("\n*** Todas las pruebas finalizaron ***");
    # (5*CLK_PERIOD_NS);
    $finish;
  end

endmodule
