// timer_15s.sv — cuenta regresiva 15→0 con tick de 1 Hz
module timer_15s #(
  parameter int START_VAL = 15
)(
  input  logic clk,
  input  logic rst_n,
  input  logic tick_1hz,
  input  logic start,     // pulso: cargar y comenzar
  input  logic pause,     // 1=pausa
  input  logic reload,    // pulso: recargar
  output logic [4:0] sec, // 0..31 (usamos 0..15)
  output logic       expired
);
  logic running;
  logic will_hit_zero;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sec     <= START_VAL[4:0];
      running <= 1'b0;
      expired <= 1'b0;
    end else begin
      expired <= 1'b0;

      if (reload) begin
        sec     <= START_VAL[4:0];
        running <= 1'b1;
      end else if (start) begin
        sec     <= START_VAL[4:0];
        running <= 1'b1;
      end else if (tick_1hz && running && !pause) begin
        if (sec != 0) begin
          will_hit_zero = (sec == 5'd1);
          sec <= sec - 5'd1;
          if (will_hit_zero) begin
            running <= 1'b0;
            expired <= 1'b1;
          end
        end
      end
    end
  end
endmodule