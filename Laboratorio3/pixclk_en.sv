module pixclk_en #(parameter int SYS_CLK_HZ=100_000_000,
                   parameter int PIX_CLK_HZ=25_000_000)
(
  input  logic clk, rst,
  output logic pix_en
);
  localparam int DIV = SYS_CLK_HZ/PIX_CLK_HZ;
  localparam int CNTW = $clog2(DIV);
  logic [CNTW-1:0] cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt   <= '0;
      pix_en<= 1'b0;
    end else begin
      if (cnt==DIV-1) begin
        cnt   <= '0;
        pix_en<= 1'b1;
      end else begin
        cnt   <= cnt+1;
        pix_en<= 1'b0;
      end
    end
  end
endmodule
