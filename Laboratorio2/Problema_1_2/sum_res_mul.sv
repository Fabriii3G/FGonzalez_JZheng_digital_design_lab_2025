// ----------------------------------------------
// Ripple-Carry Adder parametrizable (N bits)
// Cout es el acarreo final.  :contentReference[oaicite:4]{index=4}
// ----------------------------------------------
module rca_adder #(
  parameter int N = 4
)(
  input  logic [N-1:0] a, b,
  input  logic         cin,
  output logic [N-1:0] sum,
  output logic         cout
);
  logic [N:0] c;
  assign c[0] = cin;

  genvar i;
  generate
    for (i = 0; i < N; i++) begin : GEN_FA
      full_adder fa_i(
        .x   (a[i]),
        .y   (b[i]),
        .cin (c[i]),
        .s   (sum[i]),
        .cout(c[i+1])
      );
    end
  endgenerate

  assign cout = c[N];
endmodule

// ----------------------------------------------
// Ripple-Borrow Subtractor parametrizable (N bits)
// bout es el préstamo final.  :contentReference[oaicite:5]{index=5}
// ----------------------------------------------
module ripple_subtractor #(
  parameter int N = 4
)(
  input  logic [N-1:0] a, b,
  input  logic         bin,     // préstamo inicial (0 por defecto)
  output logic [N-1:0] diff,
  output logic         bout
);
  logic [N:0] br;
  assign br[0] = bin;

  genvar i;
  generate
    for (i = 0; i < N; i++) begin : GEN_FS
      full_subtractor fs_i(
        .a   (a[i]),
        .b   (b[i]),
        .bin (br[i]),
        .d   (diff[i]),
        .bout(br[i+1])
      );
    end
  endgenerate

  assign bout = br[N];
endmodule

// ----------------------------------------------------
// Multiplicador en arreglo (unsigned) N x N -> 2N bits
// - Productos parciales con AND
// - Acumulación con cadena de RCA de 2N bits (estructural)
// Sin always_*; solo generates y assigns (amigable a Quartus 20.1)
// ----------------------------------------------------
module array_multiplier #(
  parameter int N = 4
)(
  input  logic [N-1:0]     a,
  input  logic [N-1:0]     b,
  output logic [2*N-1:0]   p
);
  // Matriz de productos parciales: pp[i][j] = a[i] & b[j]
  logic [N-1:0] pp [N-1:0];

  genvar i, j;
  generate
    for (i = 0; i < N; i++) begin : GEN_PP_I
      for (j = 0; j < N; j++) begin : GEN_PP_J
        assign pp[i][j] = a[i] & b[j];
      end
    end
  endgenerate

  // Cada fila "term[i]" es pp[i][*] desplazada i posiciones (2N bits)
  logic [2*N-1:0] term [N-1:0];

  generate
    for (i = 0; i < N; i++) begin : GEN_TERM
      for (j = 0; j < 2*N; j++) begin : GEN_TERM_SET
        // Una sola asignación por bit:
        // si j está en [i .. i+N-1], tomar pp[i][j-i]; si no, 0
        assign term[i][j] = ((j >= i) && (j < i + N)) ? pp[i][j - i] : 1'b0;
      end
    end
  endgenerate

  // Cadena de sumadores RCA de 2N bits:
  // acc0 = term0
  // acc1 = acc0 + term1
  // ...
  // accN-1 = accN-2 + termN-1 => p
  logic [2*N-1:0] acc   [N-1:0];
  logic           carry [N-1:0];

  assign acc[0]   = term[0];
  assign carry[0] = 1'b0; 

  generate
    for (i = 1; i < N; i++) begin : GEN_ACC
      logic [2*N-1:0] sum_i;
      logic           cout_i;

      // Reutiliza tu sumador parametrizable a 2N bits
      rca_adder #(.N(2*N)) u_add2N (
        .a   (acc[i-1]),
        .b   (term[i]),
        .cin (1'b0),
        .sum (sum_i),
        .cout(cout_i)
      );

      assign acc[i]   = sum_i;
      assign carry[i] = cout_i; 
    end
  endgenerate

  assign p = acc[N-1];
endmodule

