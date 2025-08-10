module Testbench;

    // Parámetros de prueba
    reg clk;
    reg reset;
    reg enable;
    wire [5:0] out_2, out_4, out_6;

    // Instancias de los contadores
    Contador #(2) contador_2 (.clk(clk), .reset(reset), .enable(enable), .out(out_2));
    Contador #(4) contador_4 (.clk(clk), .reset(reset), .enable(enable), .out(out_4));
    Contador #(6) contador_6 (.clk(clk), .reset(reset), .enable(enable), .out(out_6));

    // Generación de reloj
    always begin
        clk = 0;
        #5 clk = 1;
        #5;
    end

    initial begin
        // Inicialización
        reset = 0;
        enable = 0;

        // Test para contador de 2 bits
        #10 reset = 1; enable = 1; // Reset
        #10 reset = 0;
        #50; // Simulación por un tiempo
        $display("Contador 2 bits: %b", out_2);

        // Test para contador de 4 bits
        #10 reset = 1; enable = 1; // Reset
        #10 reset = 0;
        #50;
        $display("Contador 4 bits: %b", out_4);

        // Test para contador de 6 bits
        #10 reset = 1; enable = 1; // Reset
        #10 reset = 0;
        #50;
        $display("Contador 6 bits: %b", out_6);

        // Finalización de simulación
        $finish;
    end
endmodule
