// videoGen.sv — Fondo + UNA carta (sin latches, sin drivers múltiples)
module videoGen(
  input  logic [9:0] x,
  input  logic [9:0] y,
  output logic [7:0] r,
  output logic [7:0] g,
  output logic [7:0] b
);
  // fondo
  localparam logic [7:0] BG_R = 8'd0, BG_G = 8'd90, BG_B = 8'd0;

  // Instancia de UNA carta
  logic hit;
  logic [7:0] Rc, Gc, Bc;

  vga_card #(
    .X0(260), .Y0(140),
    .W (120), .H (160)
  ) u_card (
    .x(x), .y(y),
    .face_up (1'b1),     // carta boca arriba
    .highlight(1'b1),    // borde amarillo
    .suit_id (2'd0),     // 0=diamante
    .hit(hit), .R(Rc), .G(Gc), .B(Bc)
  );

  // ÚNICO driver de r,g,b (sin latches)
  always_comb begin
    // fondo por defecto siempre asignado
    r = BG_R; g = BG_G; b = BG_B;
    // si cae dentro de la carta, sobreescribe
    if (hit) begin
      r = Rc; g = Gc; b = Bc;
    end
  end
endmodule
