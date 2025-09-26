module btn_onepulse #(
  parameter int DEBOUNCE_CLKS = 250_000
)(
  input  logic clk, rst_n,
  input  logic btn_async,
  output logic pulse
);
  logic s0, s1;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin s0<=0; s1<=0; end
    else begin s0<=btn_async; s1<=s0; end
  end

  logic stable, prev_stable;
  logic [31:0] cnt;
  logic armed;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt<=0; stable<=0; prev_stable<=0; armed<=1'b0;
    end else begin
      prev_stable <= stable;
      if (s1==stable) begin
        cnt <= 0;
      end else if (cnt < DEBOUNCE_CLKS) begin
        cnt <= cnt + 1;
      end else begin
        stable <= s1;   // alcanzó estabilidad → actualiza
        cnt    <= 0;
        armed  <= 1'b1; // a partir de la **primera** estabilidad, habilita flancos
      end
    end
  end

  assign pulse = armed && (stable && !prev_stable);
endmodule
