// tick_1hz.sv — genera un pulso de 1 ciclo cada 1 segundo
module tick_1hz #(
  parameter int unsigned SYS_CLK_HZ = 50_000_000
)(
  input  logic clk,
  input  logic rst_n,       // activo en 0
  output logic tick_1hz     // pulso 1 ciclo cada 1 s
);
  localparam int unsigned N = SYS_CLK_HZ - 1;
  logic [$clog2(SYS_CLK_HZ)-1:0] cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt     <= '0;
      tick_1hz <= 1'b0;
    end else begin
      tick_1hz <= 1'b0;
      if (cnt == N) begin
        cnt     <= '0;
        tick_1hz <= 1'b1;
      end else begin
        cnt <= cnt + 1'b1;
      end
    end
  end
endmodule
