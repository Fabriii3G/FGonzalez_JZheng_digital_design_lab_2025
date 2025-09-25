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

  // Mazo fijo: dos copias de 0..7, barajadas
  // (cada número es un símbolo único)
  localparam logic [3:0] LAYOUT [16] = '{
    4, 0, 7, 3, 6, 2, 5, 1,
    1, 5, 2, 6, 3, 7, 0, 4
  };

  always_comb begin
    for (int i = 0; i < 16; i++) begin
      state[i]     = CARD_UP;     // demo: todas boca arriba
      symbol_id[i] = LAYOUT[i];   // 0..7, dos veces cada uno
    end
    hi = 4'd0; // highlight en carta 0 (demo)
  end

  // ÚNICO driver de r,g,b: la instancia de vga_cards
  vga_cards u_cards (
    .clk          (1'b0),    // no usado internamente
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
