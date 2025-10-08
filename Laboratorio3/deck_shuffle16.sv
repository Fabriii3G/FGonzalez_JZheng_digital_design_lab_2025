// deck_shuffle16.sv — Fisher–Yates para 16 cartas (8 pares) 
module deck_shuffle16 #(
  parameter int N_CARDS   = 16,
  parameter int N_SYMBOLS = N_CARDS/2
)(
  input  logic              clk,
  input  logic              rst_n,     // reset global
  input  logic              start_i,   // pulso: iniciar barajado
  input  logic [7:0]        seed_i,    // semilla capturada de un PRBS libre
  output logic              busy_o,
  output logic              done_o,
  output logic [3:0]        layout_o [N_CARDS-1:0]
);

  // Arreglo interno (4 bits por carta: 0..7)
  logic [3:0] arr_q [N_CARDS-1:0], arr_d [N_CARDS-1:0];

  // Estado del barajador
  typedef enum logic [1:0] {S_IDLE, S_INIT, S_SWAP, S_DONE} shuf_e;
  shuf_e st_q, st_d;

  logic [4:0] i_q, i_d;        // i: 15..0
  logic [7:0] rnd_q, rnd_d;    // PRNG interno

  // PRNG interno simple (LFSR) — sembrado con seed_i en cada start
  function automatic [7:0] lfsr8_next(input [7:0] r);
    lfsr8_next = {r[6:0], r[7]^r[5]^r[4]^r[3]};
  endfunction

  // ===== Cálculo de j con anchos explícitos (evita truncation) =====
  logic [4:0] i_plus1;
  logic [4:0] mod_a, mod_b;
  logic [4:0] j_idx;

  always_comb begin
    i_plus1 = i_q + 5'd1;                 // 1..16
    mod_a   = {1'b0, rnd_q[3:0]};         // 0..15 (5 bits)
    mod_b   = (i_q == 5'd0) ? 5'd1 : i_plus1; // evitar %0
    j_idx   = (i_q == 5'd0) ? 5'd0 : (mod_a % mod_b); // 0..i
  end

  // ===== Combinacional principal =====
  integer k1;                 // índice for combinacional
  logic [3:0] tmp;            // dar default para evitar latch

  always_comb begin
    // defaults
    st_d  = st_q;
    i_d   = i_q;
    rnd_d = rnd_q;
    tmp   = 4'd0;

    for (k1 = 0; k1 < N_CARDS; k1++) begin
      arr_d[k1] = arr_q[k1];
    end

    unique case (st_q)
      S_IDLE: begin
        if (start_i) st_d = S_INIT;
      end

      S_INIT: begin
        // Rellenar [0,0,1,1,...,7,7]
        for (k1 = 0; k1 < N_CARDS; k1++) begin
          arr_d[k1] = $unsigned(k1 >> 1); // 0..7
        end
        i_d   = N_CARDS-1;          // 15
        rnd_d = seed_i ^ 8'h5A;     // semilla mezclada
        st_d  = S_SWAP;
      end

      S_SWAP: begin
        rnd_d = lfsr8_next(rnd_q);

        // swap arr[i] <-> arr[j]
        tmp                      = arr_q[i_q[3:0]];
        arr_d[i_q[3:0]]          = arr_q[j_idx[3:0]];
        arr_d[j_idx[3:0]]        = tmp;

        if (i_q == 5'd0) st_d = S_DONE;
        else             i_d  = i_q - 5'd1;
      end

      S_DONE: begin
        // Quedar hasta próximo start
        if (start_i) st_d = S_INIT;
      end
    endcase
  end

  // ===== Secuencial =====
  integer k2; // índice for secuencial
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st_q  <= S_IDLE;
      i_q   <= 5'd0;
      rnd_q <= 8'hA5;
      for (k2 = 0; k2 < N_CARDS; k2++) begin
        arr_q[k2] <= $unsigned(k2 >> 1); // 0..7
      end
    end else begin
      st_q  <= st_d;
      i_q   <= i_d;
      rnd_q <= rnd_d;
      for (k2 = 0; k2 < N_CARDS; k2++) begin
        arr_q[k2] <= arr_d[k2];
      end
    end
  end

  // ===== Salidas =====
  generate
    genvar g;
    for (g = 0; g < N_CARDS; g++) begin : G_OUT
      assign layout_o[g] = arr_q[g];
    end
  endgenerate

  assign busy_o = (st_q == S_INIT) || (st_q == S_SWAP);
  assign done_o = (st_q == S_DONE);

endmodule
