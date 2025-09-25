import lab3_params::*;

module card_bank (
  input  logic                clk, rst,
  // control
  input  logic                open_en,
  input  logic [3:0]          open_idx,
  input  logic                close_pair_en,
  input  logic [3:0]          close_a, close_b,
  input  logic                lock_pair_en,
  input  logic [3:0]          lock_a, lock_b,
  // lectura
  output card_state_e state [15:0],
  output logic        [3:0]   symbol_id [15:0]
);
  // Mapeo de símbolos: 8 parejas (ids 0..7), duplicadas
  // (En producción puedes randomizar con LFSR al reset)
  localparam logic [3:0] INIT_IDS [16] = '{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

  card_state_e st [16];
  logic [3:0]  id [16];

  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      for (i=0;i<16;i++) begin
        st[i] <= CARD_DOWN;
        id[i] <= INIT_IDS[i];
      end
    end else begin
      if (open_en)       st[open_idx] <= CARD_UP;
      if (close_pair_en) begin
        st[close_a] <= CARD_DOWN;
        st[close_b] <= CARD_DOWN;
      end
      if (lock_pair_en) begin
        st[lock_a] <= CARD_MATCH;
        st[lock_b] <= CARD_MATCH;
      end
    end
  end

  // salidas
  generate
    genvar k;
    for (k=0;k<16;k++) begin : OUTS
      assign state[k]     = st[k];
      assign symbol_id[k] = id[k];
    end
  endgenerate
endmodule
