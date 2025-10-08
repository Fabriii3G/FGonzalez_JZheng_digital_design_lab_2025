// videoGen.sv — dibuja tablero y overlay de ganador/empate
import lab3_params::*;

module videoGen(
  input  logic [9:0] x,
  input  logic [9:0] y,
  input  logic       visible,
  input  card_state_e state     [15:0],
  input  logic [3:0]  symbol_id [15:0],
  input  logic [3:0]  hi,
  // === señales nuevas para overlay ===
  input  logic       game_over,
  input  logic       winner_p2,
  input  logic       tie,
  output logic [7:0]  r,
  output logic [7:0]  g,
  output logic [7:0]  b
);

  // --- RGB base del tablero ---
  logic [7:0] rb, gb, bb;
  vga_cards u_cards (
    .clk          (1'b0),
    .x            (x),
    .y            (y),
    .visible      (visible),
    .state        (state),
    .symbol_id    (symbol_id),
    .highlight_idx(hi),
    .R            (rb),
    .G            (gb),
    .B            (bb)
  );

  // ================== Overlay de ganador ==================

  // Caja centrada
  localparam int BOX_W  = 320;
  localparam int BOX_H  = 96;
  localparam int BOX_X0 = (640-BOX_W)/2;
  localparam int BOX_Y0 = (480-BOX_H)/2;
  localparam int BOX_X1 = BOX_X0 + BOX_W;
  localparam int BOX_Y1 = BOX_Y0 + BOX_H;

  // Mini-fuente 8x8 para: P,1,2,W,I,N,S, espacio, T, E
  function automatic logic glyph8x8(
    input logic [7:0] ch,
    input logic [2:0] cx, cy
  );
    logic [7:0] row;
    begin
      case (ch)
        "P": case (cy)
          0: row=8'b11111000; 1: row=8'b10000100; 2: row=8'b10000100; 3: row=8'b11111000;
          4: row=8'b10000000; 5: row=8'b10000000; 6: row=8'b10000000; 7: row=8'b00000000;
        endcase
        "1": case (cy)
          0: row=8'b00110000; 1: row=8'b01010000; 2: row=8'b00010000; 3: row=8'b00010000;
          4: row=8'b00010000; 5: row=8'b00010000; 6: row=8'b01111100; 7: row=8'b00000000;
        endcase
        "2": case (cy)
          0: row=8'b01111000; 1: row=8'b10000100; 2: row=8'b00000100; 3: row=8'b00011000;
          4: row=8'b01100000; 5: row=8'b10000000; 6: row=8'b11111100; 7: row=8'b00000000;
        endcase
        "W": case (cy)
          0: row=8'b10000100; 1: row=8'b10000100; 2: row=8'b10010100; 3: row=8'b10010100;
          4: row=8'b10101100; 5: row=8'b11000100; 6: row=8'b10000100; 7: row=8'b00000000;
        endcase
        "I": case (cy)
          0: row=8'b11111100; 1: row=8'b00010000; 2: row=8'b00010000; 3: row=8'b00010000;
          4: row=8'b00010000; 5: row=8'b00010000; 6: row=8'b11111100; 7: row=8'b00000000;
        endcase
        "N": case (cy)
          0: row=8'b10000100; 1: row=8'b11000100; 2: row=8'b10100100; 3: row=8'b10010100;
          4: row=8'b10001100; 5: row=8'b10000100; 6: row=8'b10000100; 7: row=8'b00000000;
        endcase
        "S": case (cy)
          0: row=8'b01111100; 1: row=8'b10000000; 2: row=8'b10000000; 3: row=8'b01111000;
          4: row=8'b00000100; 5: row=8'b00000100; 6: row=8'b11111000; 7: row=8'b00000000;
        endcase
        "T": case (cy)
          0: row=8'b11111100; 1: row=8'b00100000; 2: row=8'b00100000; 3: row=8'b00100000;
          4: row=8'b00100000; 5: row=8'b00100000; 6: row=8'b00100000; 7: row=8'b00000000;
        endcase
        "E": case (cy)
          0: row=8'b11111100; 1: row=8'b10000000; 2: row=8'b10000000; 3: row=8'b11111000;
          4: row=8'b10000000; 5: row=8'b10000000; 6: row=8'b11111100; 7: row=8'b00000000;
        endcase
        " ": row = 8'b00000000;
        default: row = 8'b00000000;
      endcase
      glyph8x8 = row[7 - cx];
    end
  endfunction

  // ===== Mensajes (constantes como arreglos desempaquetados) =====
  localparam int MSG_LEN  = 7;
  localparam int MSGT_LEN = 3;

  // Nota: usar aggregate con comilla: '{
  localparam logic [7:0] MSG_P1  [0:MSG_LEN-1]  = '{
    "P","1"," ","W","I","N","S"
  };
  localparam logic [7:0] MSG_P2  [0:MSG_LEN-1]  = '{
    "P","2"," ","W","I","N","S"
  };
  localparam logic [7:0] MSG_TIE [0:MSGT_LEN-1] = '{
    "T","I","E"
  };

  // Layout de texto
  localparam int CHAR_W = 8;
  localparam int CHAR_H = 8;
  localparam int SCALE  = 3;                 // 24x24 por char
  localparam int PX     = BOX_X0 + 24;       // margen interno
  localparam int PY     = BOX_Y0 + 24;

  // Blend simple
  function automatic [7:0] blend8(input [7:0] fg, input [7:0] bg, input [7:0] alpha);
    int tmp;
    begin
      tmp = fg*alpha + bg*(8'd255 - alpha);
      blend8 = tmp/255;
    end
  endfunction

  // Colores overlay
  localparam logic [7:0] BOX_R = 8'd0,   BOX_G = 8'd0,   BOX_B = 8'd0;
  localparam logic [7:0] TXT_R = 8'd255, TXT_G = 8'd255, TXT_B = 8'd255;
  localparam logic [7:0] BOX_A = 8'd160; // ~63% opaco

  // --- Combinacional final ---
  always_comb begin
    // Variables locales (declaradas arriba del bloque para Quartus)
    integer      relx, rely, cell_x, cell_y;
    integer      len;
    logic [7:0]  ch;

    // Base del tablero
    r = rb; g = gb; b = bb;

    if (visible && game_over) begin
      // 1) Caja translúcida
      if (x >= BOX_X0 && x < BOX_X1 && y >= BOX_Y0 && y < BOX_Y1) begin
        r = blend8(BOX_R, r, BOX_A);
        g = blend8(BOX_G, g, BOX_A);
        b = blend8(BOX_B, b, BOX_A);
      end

      // 2) Texto
      relx = x - PX;
      rely = y - PY;

      if (relx >= 0 && rely >= 0) begin
        cell_x = relx / SCALE;
        cell_y = rely / SCALE;

        if (tie) begin
          len = MSGT_LEN;
          if (cell_y < CHAR_H && cell_x < (CHAR_W*len)) begin
            ch = MSG_TIE[cell_x / CHAR_W];
            if (glyph8x8(ch, cell_x[2:0], cell_y[2:0])) begin
              r = TXT_R; g = TXT_G; b = TXT_B;
            end
          end
        end else begin
          len = MSG_LEN;
          if (cell_y < CHAR_H && cell_x < (CHAR_W*len)) begin
            ch = winner_p2 ? MSG_P2[cell_x / CHAR_W] : MSG_P1[cell_x / CHAR_W];
            if (glyph8x8(ch, cell_x[2:0], cell_y[2:0])) begin
              r = TXT_R; g = TXT_G; b = TXT_B;
            end
          end
        end
      end
    end
  end

endmodule
