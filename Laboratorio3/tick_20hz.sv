module tick_20hz(
  input  logic clk, input logic rst_n,
  output logic tick
);
  localparam int DIV = 2_500_000; // 50MHz / 2.5M = 20Hz
  logic [$clog2(DIV)-1:0] c;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin c<=0; tick<=0; end
    else if (c==DIV-1) begin c<=0; tick<=1; end
    else begin c<=c+1; tick<=0; end
  end
endmodule
