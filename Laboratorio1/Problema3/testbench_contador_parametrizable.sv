module testbench_contador_parametrizable;

    // Declaración de señales
    reg clk;
    reg reset_sw;
    reg increment_btn;
    wire [1:0] contador_2bits;  // 2 bits
    wire [3:0] contador_4bits;  // 4 bits
    wire [5:0] contador_6bits;  // 6 bits

    // Instanciación del contador para 2 bits
    contador_parametrizable #(.N(2)) contador_2 (
        .clk(clk),
        .reset_sw(reset_sw),
        .increment_btn(increment_btn),
        .contador(contador_2bits)
    );

    // Instanciación del contador para 4 bits
    contador_parametrizable #(.N(4)) contador_4 (
        .clk(clk),
        .reset_sw(reset_sw),
        .increment_btn(increment_btn),
        .contador(contador_4bits)
    );

    // Instanciación del contador para 6 bits
    contador_parametrizable #(.N(6)) contador_6 (
        .clk(clk),
        .reset_sw(reset_sw),
        .increment_btn(increment_btn),
        .contador(contador_6bits)
    );

    // Generación del reloj
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Reloj de 10 unidades de tiempo
    end

    // Proceso principal de prueba
    initial begin
        // Inicialización de señales
        reset_sw = 0;
        increment_btn = 0;

        // Simulación para 2 bits
        $display("Inicio de simulación para 2 bits");
        #5 reset_sw = 1;  // Activa el reset
        #5 reset_sw = 0;  // Desactiva el reset

        // Verificación del contador de 2 bits
        repeat (4) begin
            increment_btn = 1;
            #10 increment_btn = 0;
            #10;
        end

        // Simulación para 4 bits
        $display("Inicio de simulación para 4 bits");
        #5 reset_sw = 1;
        #5 reset_sw = 0;

        // Verificación del contador de 4 bits
        repeat (16) begin
            increment_btn = 1;
            #10 increment_btn = 0;
            #10;
        end

        // Simulación para 6 bits
        $display("Inicio de simulación para 6 bits");
        #5 reset_sw = 1;
        #5 reset_sw = 0;

        // Verificación del contador de 6 bits
        repeat (64) begin
            increment_btn = 1;
            #10 increment_btn = 0;
            #10;
        end

        $stop;  // Detener la simulación
    end

    // Verificación de resultados
    always @(contador_2bits or contador_4bits or contador_6bits) begin
        $display("Contador de 2 bits: %b", contador_2bits);
        $display("Contador de 4 bits: %b", contador_4bits);
        $display("Contador de 6 bits: %b", contador_6bits);
    end

endmodule
