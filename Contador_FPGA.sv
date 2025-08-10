module Contador_FPGA (
    input wire clk,            // Reloj de la FPGA (ej. 50/100 MHz)
    input wire reset_sw,       // Switch de reset (asíncrono)
    input wire increment_btn,  // Botón para incrementar
    input wire [3:0] preset_btns, // Botones para valor inicial (4 bits)
    input wire preset_en_btn,  // Botón para cargar valor inicial
    output wire [6:0] seg1, seg2, // Salidas a displays 7 segmentos
    output wire [3:0] anodes   // Ánodos para multiplexación
);

    // Señales internas
    wire increment_pulse;
    wire preset_pulse;
    reg [5:0] contador = 0;
    wire [3:0] digit1, digit2;
    
    // Debouncing de botones
    debouncer debounce_inc (
        .clk(clk),
        .btn_in(increment_btn),
        .btn_out(increment_clean)
    );
    
    debouncer debounce_preset (
        .clk(clk),
        .btn_in(preset_en_btn),
        .btn_out(preset_clean)
    );
    
    // Detección de flancos
    edge_detector edge_inc (
        .clk(clk),
        .signal_in(increment_clean),
        .rising_edge(increment_pulse)
    );
    
    edge_detector edge_preset (
        .clk(clk),
        .signal_in(preset_clean),
        .rising_edge(preset_pulse)
    );
    
    // Lógica del contador
    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw)
            contador <= 6'd0;
        else if (preset_pulse)
            contador <= {2'b00, preset_btns}; // Carga valor inicial
        else if (increment_pulse)
            contador <= (contador == 6'd63) ? 6'd0 : contador + 1;
    end
    
    // Conversión a BCD para display decimal
    binary_to_bcd converter (
        .binary(contador),
        .bcd0(digit1),  // Unidades (0-9)
        .bcd1(digit2)   // Decenas (0-6)
    );
    
    // Control de displays (multiplexación)
    display_controller display (
        .clk(clk),
        .digit1(digit1),
        .digit2(digit2),
        .seg1(seg1),
        .seg2(seg2),
        .anodes(anodes)
    );

endmodule 