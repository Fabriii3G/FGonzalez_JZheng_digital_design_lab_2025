module Contador_FPGA (
    input wire clk,
    input wire reset_sw,
    input wire increment_btn,  // BTN0 - Incremento normal
    input wire izquierda_btn,  // BTN1 - Ajuste display izquierdo (decenas)
    input wire derecha_btn,    // BTN2 - Ajuste display derecho (unidades)
    input wire preset_en_btn,  // BTN3 - Modo configuración
    output wire [6:0] seg1, seg2,
    output wire [3:0] anodes,
    output wire config_led
);

    // Estados del sistema
    typedef enum {
        MODO_CONTEO,
        MODO_CONFIG
    } estado_t;
    
    // Señales internas
    reg estado = MODO_CONTEO;
    reg [5:0] contador = 0;
    reg [5:0] preset_temp = 0;
    
    wire increment_pulse;
    wire izquierda_pulse;
    wire derecha_pulse;
    wire config_pulse;
    
    // Variables temporales para cálculo de decenas/unidades
    reg [2:0] decenas;
    reg [3:0] unidades;
    
    // Debouncing
    debouncer debounce_inc (
        .clk(clk),
        .btn_in(increment_btn),
        .btn_out()
    );
    
    debouncer debounce_izq (
        .clk(clk),
        .btn_in(izquierda_btn),
        .btn_out()
    );
    
    debouncer debounce_der (
        .clk(clk),
        .btn_in(derecha_btn),
        .btn_out()
    );
    
    debouncer debounce_config (
        .clk(clk),
        .btn_in(preset_en_btn),
        .btn_out()
    );
    
    // Detección de flancos
    edge_detector edge_inc (
        .clk(clk),
        .signal_in(increment_btn),
        .rising_edge(increment_pulse)
    );
    
    edge_detector edge_izq (
        .clk(clk),
        .signal_in(izquierda_btn),
        .rising_edge(izquierda_pulse)
    );
    
    edge_detector edge_der (
        .clk(clk),
        .signal_in(derecha_btn),
        .rising_edge(derecha_pulse)
    );
    
    edge_detector edge_config (
        .clk(clk),
        .signal_in(preset_en_btn),
        .rising_edge(config_pulse)
    );
    
    // Lógica principal con control de decenas (0-6) sin acarreo
    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            contador <= 6'd0;
            preset_temp <= 6'd0;
            estado <= MODO_CONTEO;
        end else begin
            // Calcular decenas y unidades
            decenas = preset_temp / 10;
            unidades = preset_temp % 10;
            
            case (estado)
                MODO_CONTEO: begin
                    if (config_pulse) begin
                        estado <= MODO_CONFIG;
                        preset_temp <= contador;
                    end else if (increment_pulse) begin
                        contador <= (contador == 6'd63) ? 6'd0 : contador + 1;
                    end
                end
                
                MODO_CONFIG: begin
                    if (config_pulse) begin
                        estado <= MODO_CONTEO;
                        contador <= preset_temp;
                    end else if (izquierda_pulse) begin
                        // Control de DECENAS (0-6) sin afectar unidades
                        if (decenas == 3'd6)
                            preset_temp <= unidades; // Solo unidades
                        else
                            preset_temp <= (preset_temp + 10) % 64; // Incrementa decenas
                    end else if (derecha_pulse) begin
                        // Control de UNIDADES (0-9) sin afectar decenas
                        if (unidades == 4'd9)
                            preset_temp <= preset_temp - 9; // Mantiene decenas
                        else
                            preset_temp <= preset_temp + 1; // Incrementa unidades
                    end
                end
            endcase
        end
    end
    
    // Conversión a BCD con control de rango
    wire [3:0] bcd_unidades, bcd_decenas;
    wire [5:0] display_value = (estado == MODO_CONFIG) ? 
                              ((preset_temp > 6'd63) ? 6'd0 : preset_temp) : 
                              contador;
    
    binary_to_bcd bcd_conv (
        .binary(display_value),
        .bcd0(bcd_unidades),
        .bcd1(bcd_decenas)
    );
    
    // Control de displays con orden corregido
    display_controller display (
        .clk(clk),
        .digit1(bcd_unidades),   // Display der (unidades)
        .digit2(bcd_decenas),     // Display izq (decenas)
        .seg1(seg1),
        .seg2(seg2),
        .anodes(anodes)
    );
    
    assign config_led = (estado == MODO_CONFIG);

endmodule 