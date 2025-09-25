// vga_cards.sv (compat Quartus 20.1: typedef para casts y sin inits no-const)
import lab3_params::*;

module vga_cards(
  input  logic clk,
  input  logic [9:0] x, y,
  input  logic visible,
  input  card_state_e state [15:0],     // arreglos no empaquetados
  input  logic [3:0]  symbol_id [15:0],
  input  logic [3:0]  highlight_idx,
  output logic [7:0]  R,G,B
);

  // Aliases de tamaño fijo para evitar truncations
  typedef logic [$clog2(GRID_COLS)-1:0] col_t; // 2 bits (4 cols)
  typedef logic [$clog2(GRID_ROWS)-1:0] row_t; // 2 bits (4 filas)
  typedef logic [11:0]                  u12_t; // 12 bits

  // Dentro del tablero?
  logic in_board;
  assign in_board = visible &&
                    (x >= BOARD_X0) && (x < BOARD_X0+BOARD_W) &&
                    (y >= BOARD_Y0) && (y < BOARD_Y0+BOARD_H);

  // Índices y coords locales (con casts explícitos)
  col_t col;
  row_t row;
  u12_t lx, ly;           // coords locales en carta
  logic [3:0] idx;


	always_comb begin
	  // Declarar primero, asignar después (compat Quartus 20.1)
	  int dx;
	  int dy;

	  dx = x - BOARD_X0;
	  dy = y - BOARD_Y0;

	  col = col_t'( dx / CARD_W );   // 2 bits
	  row = row_t'( dy / CARD_H );   // 2 bits

	  idx = row*GRID_COLS + col;     // 0..15 (4 bits)

	  // resto (mod) y cast a 12 bits
	  lx  = u12_t'( dx % CARD_W );
	  ly  = u12_t'( dy % CARD_H );
	end


  // Color de salida
  lab3_params::rgb24_t color;

  always_comb begin
    color = '{8'd0,8'd0,8'd0}; // fondo negro

    if (in_board) begin
      unique case (state[idx])
        CARD_DOWN:  color = '{8'd25,  8'd25,  8'd80 };
        CARD_UP:    color = '{8'd240, 8'd240, 8'd240};
        CARD_MATCH: color = '{8'd0,   8'd160, 8'd0  };
        default:    color = '{8'd0,   8'd0,   8'd0  };
      endcase

      // Borde
      if (lx<3 || lx>=(CARD_W-3) || ly<3 || ly>=(CARD_H-3))
        color = '{8'd200,8'd200,8'd200};

      // Resalte
      if (idx==highlight_idx && (lx<3 || lx>=(CARD_W-3) || ly<3 || ly>=(CARD_H-3)))
        color = '{8'd255,8'd255,8'd0};

      // Símbolo simple si está arriba o en match
      if (state[idx] != CARD_DOWN) begin
        int cx, cy, k, sx, sy;
        logic symbol_pixel;

        cx = CARD_W/2;
        cy = CARD_H/2;
        k  = 6 + symbol_id[idx];   // usa el id para variar tamaño
        sx = int'(lx) - cx;
        sy = int'(ly) - cy;

        symbol_pixel = ( ((lx>cx-k) && (lx<cx+k) && ((ly==cy) || (ly==cy-1))) ||
                         ((ly>cy-k) && (ly<cy+k) && ((lx==cx) || (lx==cx-1))) ||
                         ((sx*sx + sy*sy) < (k*k/2)) );

        if (symbol_pixel) color = '{8'd0,8'd0,8'd0};
      end
    end
  end

  assign R = color.r;
  assign G = color.g;
  assign B = color.b;

endmodule
