module display_controller (
    input wire clk,
    input wire [3:0] digit1,
    input wire [3:0] digit2,
    output reg [6:0] seg1,
    output reg [6:0] seg2,
    output reg [3:0] anodes
);
    // Refresh rate ~60Hz
    reg [19:0] refresh_counter;
    reg display_sel = 0;
    
    // Multiplexación
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        if (refresh_counter == 0) begin
            display_sel <= ~display_sel;
        end
        
        anodes <= 4'b1111; // Todos apagados inicialmente
        
        if (display_sel) begin
            anodes[0] <= 1'b0; // Activar display 1
            seg1 <= seven_seg(digit1);
        end else begin
            anodes[1] <= 1'b0; // Activar display 2
            seg2 <= seven_seg(digit2);
        end
    end
    
    // Conversión a 7 segmentos
    function [6:0] seven_seg(input [3:0] digit);
        case (digit)
            0: seven_seg = 7'b1000000; // 0
            1: seven_seg = 7'b1111001; // 1
            2: seven_seg = 7'b0100100; // 2
            3: seven_seg = 7'b0110000; // 3
            4: seven_seg = 7'b0011001; // 4
            5: seven_seg = 7'b0010010; // 5
            6: seven_seg = 7'b0000010; // 6
            7: seven_seg = 7'b1111000; // 7
            8: seven_seg = 7'b0000000; // 8
            9: seven_seg = 7'b0010000; // 9
            default: seven_seg = 7'b1111111; // Apagado
        endcase
    endfunction
endmodule 