module Contador #(parameter N = 4) (
    input wire clk,        // Reloj
    input wire reset,      // Reset asíncrono
    input wire enable,     // Habilitar el contador
    output reg [N-1:0] out // Salida del contador
);

    // Reset asíncrono
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 0;
        else if (enable)
            out <= out + 1;
    end

endmodule
