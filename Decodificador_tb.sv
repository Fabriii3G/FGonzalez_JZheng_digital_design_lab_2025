module Decodificador_tb;
    reg [3:0] binario;
    wire [3:0] gray_code;
    
    Decodificador uut (
        .binario(binario),
        .gray_code(gray_code)
    );
    
    initial begin
        // Inicializar entradas
        binario = 0;
        
        // Ver los cambios
        $monitor("Binario = %b, Gray = %b", binario, gray_code);
        
        // Probar todos los valores posibles
        for (integer i = 0; i < 16; i = i + 1) begin
            binario = i;
            #10;
        end
        
    end
endmodule
