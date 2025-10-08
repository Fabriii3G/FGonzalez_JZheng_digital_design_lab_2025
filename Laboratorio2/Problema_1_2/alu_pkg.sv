// ----------------------------------------------
// Paquete común de tipos y utilidades
// ----------------------------------------------
package alu_pkg;
  typedef enum logic [3:0] {
    OP_ADD = 4'h0,   // suma (RCA)
    OP_SUB = 4'h1,   // resta (Ripple-Borrow)
    OP_MUL = 4'h2,   // multiplicación en arreglo (array)
    OP_DIV = 4'h3,   // / operador permitido
    OP_MOD = 4'h4,   // % operador permitido
    OP_AND = 4'h5,
    OP_OR  = 4'h6,
    OP_XOR = 4'h7,
    OP_SLL = 4'h8,
    OP_SRL = 4'h9
  } op_t;
endpackage : alu_pkg

// ----------------------------------------------
// Half Adder (HA): s = x ^ y; c = x & y
// ----------------------------------------------
module half_adder (
  input  logic x, y,
  output logic s, c
);
  assign s = x ^ y;
  assign c = x & y;
endmodule

// ----------------------------------------------
// Full Adder (FA): s = x ^ y ^ cin;
// cout = (x & y) | (cin & (x ^ y))
// Ecuaciones del diseño (RCA).  :contentReference[oaicite:2]{index=2}
// ----------------------------------------------
module full_adder (
  input  logic x, y, cin,
  output logic s, cout
);
  logic p, g;
  assign p   = x ^ y;
  assign g   = x & y;
  assign s   = p ^ cin;
  assign cout= g | (p & cin);
endmodule

// ----------------------------------------------
// Full Subtractor (FS) para Ripple-Borrow:
// d = a ^ b ^ bin;
// bout = ( ~a & b ) | ( ~a & bin ) | ( b & bin )
// Basado en ecuaciones del documento.  :contentReference[oaicite:3]{index=3}
// ----------------------------------------------
module full_subtractor (
  input  logic a, b, bin,
  output logic d, bout
);
  assign d    = a ^ b ^ bin;
  assign bout = (~a & b) | (~a & bin) | (b & bin);
endmodule
