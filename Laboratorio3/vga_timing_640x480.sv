import lab3_params::*;

module vga_timing_640x480(
  input  logic clk, rst,
  input  logic pix_en,                 // enable de píxel (25 MHz)
  output logic hsync, vsync,
  output logic [9:0] x, y,             // coordenadas visibles
  output logic visible
);
  logic [$clog2(H_TOTAL)-1:0] hcnt;
  logic [$clog2(V_TOTAL)-1:0] vcnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      hcnt <= '0; vcnt <= '0;
    end else if (pix_en) begin
      if (hcnt == H_TOTAL-1) begin
        hcnt <= 0;
        vcnt <= (vcnt == V_TOTAL-1) ? 0 : vcnt+1;
      end else begin
        hcnt <= hcnt+1;
      end
    end
  end

  // Señales de sync (activos en bajo en VGA)
  assign hsync = ~((hcnt >= H_VISIBLE + H_FP) && (hcnt < H_VISIBLE + H_FP + H_SYNC));
  assign vsync = ~((vcnt >= V_VISIBLE + V_FP) && (vcnt < V_VISIBLE + V_FP + V_SYNC));

  // Visibilidad y coordenadas
  assign visible = (hcnt < H_VISIBLE) && (vcnt < V_VISIBLE);
  assign x = hcnt[9:0];
  assign y = vcnt[9:0];
endmodule
