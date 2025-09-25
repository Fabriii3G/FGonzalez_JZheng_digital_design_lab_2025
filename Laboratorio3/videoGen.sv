// videoGen.sv — Genera colores en base a (x,y).
// MODO_A: SOLO barras y rectángulo (sin ROM) -> define NO_CHARROM
// MODO_B: Texto desde ROM + rectángulo (requiere charrom.txt en el proyecto)

module videoGen(
  input  logic [9:0] x,
  input  logic [9:0] y,
  output logic [7:0] r,
  output logic [7:0] g,
  output logic [7:0] b
);

`ifdef NO_CHARROM
  // --- MODO_A: barras + rectángulo (sin ROM) ---
  logic inrect;
  rectgen u_rect(.x(x), .y(y),
                 .left(10'd120), .top(10'd150), .right(10'd200), .bot(10'd230),
                 .inrect(inrect));

  always_comb begin
    // Barras verticales
    unique case (x/10'd80)
      0: begin r=8'hFF; g=8'h00; b=8'h00; end
      1: begin r=8'hFF; g=8'h80; b=8'h00; end
      2: begin r=8'hFF; g=8'hFF; b=8'h00; end
      3: begin r=8'h00; g=8'hFF; b=8'h00; end
      4: begin r=8'h00; g=8'hFF; b=8'hFF; end
      5: begin r=8'h00; g=8'h00; b=8'hFF; end
      6: begin r=8'h80; g=8'h00; b=8'hFF; end
      default: begin r=8'hFF; g=8'hFF; b=8'hFF; end
    endcase
    if (inrect) begin r=8'h00; g=8'hFF; b=8'h00; end
  end

`else
  // --- MODO_B: ROM de caracteres + rectángulo ---
  logic pixel, inrect;
  logic [7:0] ch_code;

  // Selecciona una letra según Y (por ejemplo "A" + fila/8)
  // y[8:3] da 0..31 → sumamos 65 ("A")
  assign ch_code = 8'd65 + y[8:3];

  chargenrom u_chrom(
    .ch  (ch_code),
    .xoff(x[2:0]),
    .yoff(y[2:0]),
    .pixel(pixel)
  );

  rectgen u_rect(.x(x), .y(y),
                 .left(10'd120), .top(10'd150), .right(10'd200), .bot(10'd230),
                 .inrect(inrect));

  always_comb begin
    // Alterna rojo/azul por bandas de 8 líneas (y[3])
    if (y[3]==1'b0) begin
      r = {8{pixel}}; g = 8'h00;      b = 8'h00;
    end else begin
      r = 8'h00;      g = 8'h00;      b = {8{pixel}};
    end
    if (inrect) begin r=8'h00; g=8'hFF; b=8'h00; end
  end
`endif

endmodule

// --- ROM de caracteres (8x8) ---
module chargenrom(
  input  logic [7:0] ch,
  input  logic [2:0] xoff,   // 0..7
  input  logic [2:0] yoff,   // 0..7
  output logic       pixel
);
  // 256 caracteres x 8 líneas = 2048 entradas de 8 bits.
  // Guardamos cada línea como un byte (bit 7 = pixel izquierda, bit 0 = derecha)
  logic [7:0] charrom [0:2047];
  logic [7:0] line;

  // Asegúrate de agregar "charrom.txt" al proyecto (Project -> Add/Remove Files)
  initial $readmemb("charrom.txt", charrom);

  always_comb begin
    // índice = yoff + (ch << 3)
    line  = charrom[ {ch, 3'b000} + yoff ];
    pixel = line[ 3'd7 - xoff ];   // invierte el orden para izquierda→derecha
  end
endmodule

// --- Rectángulo ---
module rectgen(
  input  logic [9:0] x, y,
  input  logic [9:0] left, top, right, bot,
  output logic       inrect
);
  always_comb begin
    inrect = (x >= left) && (x < right) && (y >= top) && (y < bot);
  end
endmodule
