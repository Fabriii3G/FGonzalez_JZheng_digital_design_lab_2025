// vga_cards.sv — renderizador de tablero 4x4 sin divisiones/mod
// Compatible Quartus 20.1 (no declaraciones tardías en always_comb)

import lab3_params::*;

module vga_cards(
  input  logic                clk,           // píxel clock (vgaclk)
  input  logic [9:0]          x, y,          // coordenadas VGA
  input  logic                visible,       // 1 dentro de 640x480 (blank_b)
  input  card_state_e         state [15:0],  // estados por carta
  input  logic        [3:0]   symbol_id [15:0],
  input  logic        [3:0]   highlight_idx,
  output logic        [7:0]   R, G, B
);

  // -------------------------------------------------------------------
  // 1) Precalcular bordes del tablero (constantes de síntesis)
  // -------------------------------------------------------------------
  localparam int X0  = BOARD_X0;
  localparam int Y0  = BOARD_Y0;
  localparam int W   = CARD_W;
  localparam int H   = CARD_H;

  // columnas (4)
  localparam int X1 = X0 + W;
  localparam int X2 = X1 + W;
  localparam int X3 = X2 + W;
  localparam int X4 = X3 + W; // = X0 + BOARD_W

  // filas (4)
  localparam int Y1 = Y0 + H;
  localparam int Y2 = Y1 + H;
  localparam int Y3 = Y2 + H;
  localparam int Y4 = Y3 + H; // = Y0 + BOARD_H

  // centro de carta (constantes)
  localparam int CX = W/2;
  localparam int CY = H/2;

  // -------------------------------------------------------------------
  // 2) ¿(x,y) dentro del tablero?
  // -------------------------------------------------------------------
  logic in_board;
  always_comb begin
    in_board = visible && (x >= X0) && (x < X4) && (y >= Y0) && (y < Y4);
  end

  // -------------------------------------------------------------------
  // 3) Columnas/filas por rangos (sin /)
  // -------------------------------------------------------------------
  logic [1:0] col, row;      // 0..3
  logic [3:0] idx;           // 0..15
  int         x_base, y_base;
  logic [11:0] lx, ly;       // coords locales dentro de la carta

  always_comb begin
    // Defaults
    col    = 2'd0;
    row    = 2'd0;
    x_base = X0;
    y_base = Y0;

    // col
    if      (x < X1) begin col = 2'd0; x_base = X0; end
    else if (x < X2) begin col = 2'd1; x_base = X1; end
    else if (x < X3) begin col = 2'd2; x_base = X2; end
    else             begin col = 2'd3; x_base = X3; end

    // row
    if      (y < Y1) begin row = 2'd0; y_base = Y0; end
    else if (y < Y2) begin row = 2'd1; y_base = Y1; end
    else if (y < Y3) begin row = 2'd2; y_base = Y2; end
    else             begin row = 2'd3; y_base = Y3; end

    // idx = row*4 + col  => concat porque son 2 bits cada uno
    idx = {row, col};

    // locales
    lx = x - x_base;
    ly = y - y_base;
  end

  // -------------------------------------------------------------------
  // 4) Dibujo de una carta: borde, cara/dorso y símbolo simple
  // -------------------------------------------------------------------
  // Colores
  localparam logic [7:0] C_BG_R  = 8'd0,   C_BG_G  = 8'd90,  C_BG_B  = 8'd0;   // paño verde
  localparam logic [7:0] C_BACK_R= 8'd32,  C_BACK_G= 8'd64,  C_BACK_B= 8'd120; // dorso
  localparam logic [7:0] C_FACE_R= 8'd240, C_FACE_G= 8'd240, C_FACE_B= 8'd240; // cara
  localparam logic [7:0] C_BOR_R = 8'd200, C_BOR_G = 8'd200, C_BOR_B = 8'd200; // borde
  localparam logic [7:0] C_HIL_R = 8'd255, C_HIL_G = 8'd255, C_HIL_B = 8'd0;   // highlight
  localparam logic [7:0] C_INK_R = 8'd0,   C_INK_G = 8'd0,   C_INK_B = 8'd0;   // tinta

  // Bordes y tamaño símbolo (constantes de carta)
  localparam int BORDER = 3;
  localparam int THIN   = (W < H) ? (W/40) : (H/40); // ~delgado
  localparam int THICK  = (W < H) ? (W/16) : (H/16); // ~grueso
  localparam int KSYM   = (W < H) ? (W/4)  : (H/4);  // tamaño símbolo

  // utilidades
  function automatic int abs_i(input int v);
    abs_i = (v < 0) ? -v : v;
  endfunction

  // -------------------------------------------------------------------
  // 5) Pintado final
  // -------------------------------------------------------------------
// --- declara FUERA del always_comb si quieres —o al inicio del bloque—, pero no dos veces
	logic in_border;

	// Colores por píxel
	logic [7:0] r_pix, g_pix, b_pix;

	// Variables que usaremos dentro del always_comb (declaradas al inicio)
	card_state_e cs;
	int sx, sy;
	logic sym_on;
	int sid;

	always_comb begin
	  // Fondo por defecto
	  r_pix = C_BG_R; g_pix = C_BG_G; b_pix = C_BG_B;

	  // Por si no entramos al tablero, inicializa por defecto
	  cs      = CARD_DOWN;
	  in_border = 1'b0;
	  sx      = 0;
	  sy      = 0;
	  sym_on  = 1'b0;
	  sid     = 0;

	  if (in_board) begin
		 // Estados de la carta en (row,col)
		 cs = state[idx];

		 // Base: cara/dorso
		 if (cs == CARD_DOWN) begin
			r_pix = C_BACK_R; g_pix = C_BACK_G; b_pix = C_BACK_B;
		 end else if (cs == CARD_MATCH) begin
			r_pix = 8'd0; g_pix = 8'd160; b_pix = 8'd0;
		 end else begin
			r_pix = C_FACE_R; g_pix = C_FACE_G; b_pix = C_FACE_B;
		 end

		 // Borde
		 in_border = (lx < BORDER) || (lx >= (W - BORDER)) ||
						 (ly < BORDER) || (ly >= (H - BORDER));

		 if (in_border) begin
			if (idx == highlight_idx)
			  {r_pix, g_pix, b_pix} = {C_HIL_R, C_HIL_G, C_HIL_B};
			else
			  {r_pix, g_pix, b_pix} = {C_BOR_R, C_BOR_G, C_BOR_B};
		 end

		 // Símbolo si no está boca abajo ni en borde
		 if ((cs != CARD_DOWN) && !in_border) begin
			sx  = int'(lx) - CX;
			sy  = int'(ly) - CY;
			sid = symbol_id[idx];   // 0..15 (usamos sid[1:0])

			unique case (sid[1:0])
			  2'd0: sym_on = (abs_i(sx) + abs_i(sy)) < KSYM;            // diamante
			  2'd1: sym_on = (abs_i(sx) <= THIN) || (abs_i(sy) <= THIN); // cruz
			  2'd2: sym_on = (abs_i(sx) <= THICK);                       // barra vertical
			  default: sym_on = (abs_i(sy) <= THICK);                    // barra horizontal
			endcase

			if (sym_on) begin
			  r_pix = C_INK_R; g_pix = C_INK_G; b_pix = C_INK_B;
			end
		 end
	  end
	end

	assign R = r_pix;
	assign G = g_pix;
	assign B = b_pix;


endmodule
