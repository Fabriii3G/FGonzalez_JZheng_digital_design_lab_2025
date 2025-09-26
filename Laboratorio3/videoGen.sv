// videoGen.sv — ahora solo DIBUJA, no crea el mazo
import lab3_params::*;

module videoGen(
  input  logic [9:0] x,
  input  logic [9:0] y,
  input  logic       visible,
  input  card_state_e state     [15:0],
  input  logic [3:0]  symbol_id [15:0],
  input  logic [3:0]  hi,
  output logic [7:0]  r,
  output logic [7:0]  g,
  output logic [7:0]  b
);
  vga_cards u_cards (
    .clk          (1'b0),
    .x            (x),
    .y            (y),
    .visible      (visible),
    .state        (state),
    .symbol_id    (symbol_id),
    .highlight_idx(hi),
    .R            (r),
    .G            (g),
    .B            (b)
  );
endmodule
