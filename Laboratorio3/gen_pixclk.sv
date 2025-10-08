module gen_pixclk #(
  parameter int SYS_CLK_HZ = 50_000_000,
  parameter int PIX_CLK_HZ = 25_000_000
)(
  input  logic clk, rst,
  output logic clk_pix
);
  localparam int DIV2 = (SYS_CLK_HZ/(2*PIX_CLK_HZ)) < 1 ? 1 : (SYS_CLK_HZ/(2*PIX_CLK_HZ));
  localparam int W    = $clog2(DIV2);
  logic [W-1:0] cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= '0;
      clk_pix <= 1'b0;
    end else if (cnt == DIV2-1) begin
      cnt <= '0;
      clk_pix <= ~clk_pix;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end
endmodule
