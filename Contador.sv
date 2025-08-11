module Contador #(parameter N = 4) (
    input wire clk,          // Reloj
    input wire reset,        // Reset asincrónico
    input wire increment,    // Señal de incremento
    output reg [N-1:0] count // Salida: contador de N bits
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0; // Reset asincrónico
        end else if (increment) begin
            count <= count + 1; // Incrementar el contador
        end
    end

endmodule
