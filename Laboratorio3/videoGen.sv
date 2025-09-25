// videoGen.sv — Tablero 4×4 con 8 pares usando vga_cards
import lab3_params::*;

module videoGen(
  input  logic [9:0] x,
  input  logic [9:0] y,
  input  logic       visible,   // pásale blank_b del controlador
  output logic [7:0] r,
  output logic [7:0] g,
  output logic [7:0] b
);
  // Arreglos del tablero
  card_state_e state     [15:0];
  logic [3:0]  symbol_id [15:0];
  logic [3:0]  hi;

  // Config demo: todas UP; símbolos en pares 0,0,1,1,...,7,7; highlight=0
  always_comb begin
    for (int i = 0; i < 16; i++) begin
      state[i]     = CARD_UP;
      symbol_id[i] = ((i >> 1) & 4'd15);
      // Alternativas equivalentes:
      // symbol_id[i] = logic [3:0]'(i >> 1);
      // symbol_id[i] = (i >> 1) & 4'hF;
    end
    hi = 4'd0;
  end

  // ÚNICO driver de r,g,b: la instancia de vga_cards
  vga_cards u_cards (
    .clk          (1'b0),    // no usado internamente
    .x            (x),
    .y            (y),
    .visible      (visible), // blank_b
    .state        (state),
    .symbol_id    (symbol_id),
    .highlight_idx(hi),
    .R            (r),
    .G            (g),
    .B            (b)
  );
endmodule
