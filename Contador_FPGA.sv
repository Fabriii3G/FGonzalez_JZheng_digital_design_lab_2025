module Contador_FPGA (
    input wire clk,
    input wire reset_sw,
    input wire increment_btn,  // BTN0 - Incremento normal
    input wire izquierda_btn,  // BTN1 - Ajuste decenas (0-6)
    input wire derecha_btn,    // BTN2 - Ajuste unidades (0-9)
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
    reg [3:0] preset_unidades = 0;  // Almacena unidades (0-9) independientemente
    reg [2:0] preset_decenas = 0;   // Almacena decenas (0-6) independientemente
    
    wire increment_pulse;
    wire izquierda_pulse;
    wire derecha_pulse;
    wire config_pulse;
    
    // Debouncers para los botones
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
    
    // Lógica principal del contador - Versión Simplificada
    always @(posedge clk or posedge reset_sw) begin
        if (reset_sw) begin
            contador <= 6'd0;
            preset_unidades <= 4'd0;
            preset_decenas <= 3'd0;
            estado <= MODO_CONTEO;
        end else begin
            case (estado)
                MODO_CONTEO: begin
                    if (config_pulse) begin
                        // Entrar en modo configuración
                        estado <= MODO_CONFIG;
                        // Cargar el valor actual (separar decenas y unidades)
                        preset_unidades <= contador % 10;
                        preset_decenas <= contador / 10;
                    end else if (increment_pulse) begin
                        // Incremento normal
                        contador <= (contador == 6'd63) ? 6'd0 : contador + 1;
                    end
                end
                
                MODO_CONFIG: begin
                    if (config_pulse) begin
                        // Salir del modo configuración
                        estado <= MODO_CONTEO;
                        // Combinar decenas y unidades (sin verificación de acarreo)
                        contador <= (preset_decenas * 10) + preset_unidades;
                    end else if (izquierda_pulse) begin
                        // Solo modifica decenas (0-6)
                        preset_decenas <= (preset_decenas == 3'd6) ? 3'd0 : preset_decenas + 1;
                    end else if (derecha_pulse) begin
                        // Solo modifica unidades (0-9)
                        preset_unidades <= (preset_unidades == 4'd9) ? 4'd0 : preset_unidades + 1;
                    end
                end
            endcase
        end
    end
    
    // Mostrar valores directamente de los registros independientes en modo configuración
    wire [3:0] display_unidades = (estado == MODO_CONFIG) ? preset_unidades : contador % 10;
    wire [3:0] display_decenas = (estado == MODO_CONFIG) ? preset_decenas : contador / 10;
    
    // Control de displays (implementación directa)
    display_controller display (
        .clk(clk),
        .digit1(display_unidades),   // Display derecho (unidades)
        .digit2(display_decenas),    // Display izquierdo (decenas)
        .seg1(seg1),
        .seg2(seg2),
        .anodes(anodes)
    );
    
    // LED indicador de modo configuración
    assign config_led = (estado == MODO_CONFIG);

endmodule 