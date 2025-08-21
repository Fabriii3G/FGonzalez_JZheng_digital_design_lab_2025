module contador_parametrizable #(
    parameter N = 4  // Número de bits del contador (puede ser 2, 4, 6, etc.)
)(
    input wire clk,
    input wire reset_sw,  // Reset asincrónico
    input wire increment_btn,  // Botón de incremento
    output reg [N-1:0] contador  // Salida del contador
);

    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            contador <= 0;  // Reset del contador a 0
        end else if (increment_btn) begin
            contador <= contador + 1;
        end
    end

endmodule
