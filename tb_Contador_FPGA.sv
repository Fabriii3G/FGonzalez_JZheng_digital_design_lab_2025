module tb_Contador_FPGA;
    // Declaración de señales
    reg clk;
    reg reset;
    reg increment;
    wire [5:0] count_6bits;  // Salida del contador de 6 bits
    wire [1:0] count_2bits;  // Salida del contador de 2 bits

    // Instanciamos el contador de 6 bits
    Contador #(6) uut_6bits (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .count(count_6bits)
    );

    // Instanciamos el contador de 2 bits
    Contador #(2) uut_2bits (
        .clk(clk),
        .reset(reset),
        .increment(increment),
        .count(count_2bits)
    );

    // Generamos el reloj (ciclo de 10 unidades)
    always begin
        #5 clk = ~clk;  // Cambiar cada 5 unidades de tiempo (frecuencia de 100 MHz)
    end

    initial begin
        // Inicialización de señales
        clk = 0;
        reset = 0;
        increment = 0;

        // Test de Incremento para 6 bits antes de aplicar el reset
        $display("--------------------------------------------------------");
        $display("Testing Incremento de 6 bits y luego Reset");

        increment = 1; // Activamos la señal de incremento para 6 bits

        // Imprimimos y hacemos el incremento paso a paso
        #5;  // Esperamos 1 ciclo de reloj
        $display("Incrementando... Valor del contador de 6 bits: %d", count_6bits);
        
        #5;  // Esperamos otro ciclo de reloj
        $display("Incrementando... Valor del contador de 6 bits: %d", count_6bits);

        #5;  // Otro ciclo de reloj
        $display("Incrementando... Valor del contador de 6 bits: %d", count_6bits);
        
        #5;
        $display("Incrementando... Valor del contador de 6 bits: %d", count_6bits);
        
        #5;
        $display("Incrementando... Valor del contador de 6 bits: %d", count_6bits);

        increment = 0; // Desactivamos la señal de incremento
        #10; // Pausa para mostrar el valor antes de aplicar el reset

        // Ahora aplicamos el reset y verificamos si vuelve a cero
        reset = 1; // Activamos el reset
        #5; // Esperamos 1 ciclo de reloj
        $display("Aplicando Reset... Valor del contador de 6 bits después de Reset: %d", count_6bits);

        reset = 0; // Desactivamos el reset
        #5;  // Esperamos otro ciclo de reloj para ver si el contador vuelve a contar

        $display("--------------------------------------------------------");
        $display("Valor del contador de 6 bits después de desactivar el reset: %d", count_6bits);
        
        // Continuamos contando después de reset
        increment = 1;  // Activamos el incremento nuevamente
        #5;  // Un ciclo de reloj
        $display("Reiniciado... Valor del contador de 6 bits: %d", count_6bits);

        #5;  // Otro ciclo de reloj
        $display("Reiniciado... Valor del contador de 6 bits: %d", count_6bits);

        #5;  // Otro ciclo de reloj
        $display("Reiniciado... Valor del contador de 6 bits: %d", count_6bits);

        #5;  // Otro ciclo de reloj
        $display("Reiniciado... Valor del contador de 6 bits: %d", count_6bits);

        #5;  // Otro ciclo de reloj
        $display("Reiniciado... Valor del contador de 6 bits: %d", count_6bits);

        increment = 0; // Desactivamos el incremento
        #10; // Pausa para observar el valor final

        // Finalizamos la simulación
        $finish;
    end
endmodule
