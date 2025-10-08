module vga_card #(
  parameter int X0 = 160,
  parameter int Y0 = 120,
  parameter int W  = 120,
  parameter int H  = 160,
  parameter int BORDER = 3
)(
  input  logic [9:0] x,
  input  logic [9:0] y,
  input  logic       face_up,
  input  logic       highlight,
  input  logic [1:0] suit_id,
  output logic       hit,
  output logic [7:0] R, G, B
);

  // Colores
  localparam logic [7:0] C_BACK_R = 8'd32,  C_BACK_G = 8'd64,  C_BACK_B = 8'd120;
  localparam logic [7:0] C_FACE_R = 8'd240, C_FACE_G = 8'd240, C_FACE_B = 8'd240;
  localparam logic [7:0] C_BOR_R  = 8'd200, C_BOR_G  = 8'd200, C_BOR_B  = 8'd200;
  localparam logic [7:0] C_HIL_R  = 8'd255, C_HIL_G  = 8'd255, C_HIL_B  = 8'd0;
  localparam logic [7:0] C_INK_R  = 8'd0,   C_INK_G  = 8'd0,   C_INK_B  = 8'd0;

  localparam int CX = W/2;
  localparam int CY = H/2;

  // ✅ Constantes derivadas de parámetros (no generan latches)
  localparam int THIN  = (W < H) ? (W/40) : (H/40);
  localparam int THICK = (W < H) ? (W/16) : (H/16);
  localparam int KSYM  = (W < H) ? (W/4)  : (H/4);

  // Región y coords locales
  logic inx, iny;
  assign inx = (x >= X0) && (x < X0 + W);
  assign iny = (y >= Y0) && (y < Y0 + H);
  assign hit = inx && iny;

  logic [11:0] lx, ly;
  always_comb begin
    lx = x - X0;
    ly = y - Y0;
  end

  function automatic int abs_i(input int v);
    abs_i = (v < 0) ? -v : v;
  endfunction

  // Señales internas
  logic in_border;
  int   sx, sy;
  logic sym_on;

  always_comb begin
    // ✅ Valores por defecto en TODOS los caminos (evita latches)
    R = 8'd0; G = 8'd90; B = 8'd0;  // paño verde
    in_border = 1'b0;
    sym_on    = 1'b0;
    sx = 0; sy = 0;

    if (hit) begin
      // Cara/dorso
      if (face_up) begin
        R = C_FACE_R; G = C_FACE_G; B = C_FACE_B;
      end else begin
        R = C_BACK_R; G = C_BACK_G; B = C_BACK_B;
      end

      // Borde
      in_border = (lx < BORDER) || (lx >= (W - BORDER)) ||
                  (ly < BORDER) || (ly >= (H - BORDER));
      if (in_border) begin
        if (highlight) {R,G,B} = {C_HIL_R, C_HIL_G, C_HIL_B};
        else            {R,G,B} = {C_BOR_R, C_BOR_G, C_BOR_B};
      end

      // Símbolo si boca arriba y no borde
      if (face_up && !in_border) begin
        sx = int'(lx) - CX;
        sy = int'(ly) - CY;

        unique case (suit_id)
          2'd0: sym_on = (abs_i(sx) + abs_i(sy)) < KSYM;               // diamante
          2'd1: sym_on = (abs_i(sx) <= THIN) || (abs_i(sy) <= THIN);   // cruz delgada
          2'd2: sym_on = (abs_i(sx) <= THICK);                          // barra vertical
          default: sym_on = (abs_i(sy) <= THICK);                       // barra horizontal
        endcase

        if (sym_on) begin
          R = C_INK_R; G = C_INK_G; B = C_INK_B;
        end
      end
    end
  end
endmodule
