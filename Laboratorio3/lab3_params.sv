package lab3_params;
  // Relojes
  parameter int SYS_CLK_HZ    = 100_000_000; // ajusta a tu board (50e6, 100e6, etc.)
  parameter int PIX_CLK_HZ    = 25_000_000;  // VGA 640x480 ~25 MHz (25.175 aprox)

  // VGA 640x480@60 timing (pix clock ~25 MHz)
  parameter int H_VISIBLE = 640;
  parameter int H_FP      = 16;
  parameter int H_SYNC    = 96;
  parameter int H_BP      = 48;
  parameter int H_TOTAL   = H_VISIBLE + H_FP + H_SYNC + H_BP;

  parameter int V_VISIBLE = 480;
  parameter int V_FP      = 10;
  parameter int V_SYNC    = 2;
  parameter int V_BP      = 33;
  parameter int V_TOTAL   = V_VISIBLE + V_FP + V_SYNC + V_BP;

  // Tablero (4x4)
  parameter int GRID_COLS = 4;
  parameter int GRID_ROWS = 4;

  // Cada carta en pixeles (ajustado para centrar tablero)
  parameter int CARD_W = 120;
  parameter int CARD_H = 100;

  // Margen superior/izquierdo para centrar las 4x4 cartas
  parameter int BOARD_W = GRID_COLS * CARD_W;
  parameter int BOARD_H = GRID_ROWS * CARD_H;
  parameter int BOARD_X0 = (H_VISIBLE - BOARD_W)/2;
  parameter int BOARD_Y0 = (V_VISIBLE - BOARD_H)/2;

  // Colores (RGB 8:8:8)
  typedef struct packed {logic [7:0] r,g,b;} rgb24_t;

  // Estados de carta
  typedef enum logic [1:0] {CARD_DOWN=2'b00, CARD_UP=2'b01, CARD_MATCH=2'b10} card_state_e;

endpackage
