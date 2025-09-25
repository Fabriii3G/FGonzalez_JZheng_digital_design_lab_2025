module lfsr8(
  input  logic clk, rst,
  input  logic step,
  output logic [7:0] rnd
);
  logic [7:0] r;
  always_ff @(posedge clk) begin
    if (rst) r <= 8'hA5;
    else if (step) r <= {r[6:0], r[7]^r[5]^r[4]^r[3]};
  end
  assign rnd = r;
endmodule
