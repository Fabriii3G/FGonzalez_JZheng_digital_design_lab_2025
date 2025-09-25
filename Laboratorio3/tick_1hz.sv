module tick_1hz #(parameter int SYS_CLK_HZ=100_000_000)(
  input  logic clk, rst,
  output logic tick_1s
);
  localparam int DIV = SYS_CLK_HZ;
  localparam int W   = $clog2(DIV);
  logic [W-1:0] cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      cnt <= '0; tick_1s <= 1'b0;
    end else begin
      tick_1s <= 1'b0;
      if (cnt==DIV-1) begin
        cnt <= '0; tick_1s <= 1'b1;
      end else cnt <= cnt+1;
    end
  end
endmodule

module countdown_15s(
  input  logic clk, rst,
  input  logic tick_1s,
  input  logic load,          // cargar 15
  input  logic en,            // habilitar conteo
  output logic timeout,       // llega a 0
  output logic [3:0] bcd_tens,
  output logic [3:0] bcd_units
);
  logic [4:0] val; // 0..31
  always_ff @(posedge clk) begin
    if (rst) begin
      val<=15; timeout<=1'b0;
    end else begin
      timeout<=1'b0;
      if (load)        val <= 15;
      else if (en && tick_1s) begin
        if (val!=0) val <= val-1;
        if (val==1) timeout<=1'b1; // al siguiente será 0
      end
    end
  end

  // a BCD
  always_comb begin
    bcd_tens  = (val>=10) ? 1 : 0;
    bcd_units = (val>=10) ? (val-10) : val;
  end
endmodule
