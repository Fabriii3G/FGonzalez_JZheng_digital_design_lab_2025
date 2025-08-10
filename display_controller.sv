module display_controller (
    input wire clk,
    input wire [3:0] digit1,  // Unidades (display derecho)
    input wire [3:0] digit2,  // Decenas (display izquierdo)
    output reg [6:0] seg1,
    output reg [6:0] seg2,
    output reg [3:0] anodes
);
    // Tabla de conversión a 7 segmentos (0-9)
    function [6:0] seg7;
        input [3:0] num;
        begin
            case (num)
                4'd0: seg7 = 7'b1000000;
                4'd1: seg7 = 7'b1111001;
                4'd2: seg7 = 7'b0100100;
                4'd3: seg7 = 7'b0110000;
                4'd4: seg7 = 7'b0011001;
                4'd5: seg7 = 7'b0010010;
                4'd6: seg7 = 7'b0000010;
                4'd7: seg7 = 7'b1111000;
                4'd8: seg7 = 7'b0000000;
                4'd9: seg7 = 7'b0010000;
                default: seg7 = 7'b1111111;
            endcase
        end
    endfunction
    
    // Multiplexación de displays
    reg [1:0] sel = 0;
    reg [16:0] counter = 0;
    
    always @(posedge clk) begin
        counter <= counter + 1;
        if (&counter) sel <= sel + 1;
        
        case (sel)
            2'b00: begin
                anodes <= 4'b1110;
                seg1 <= seg7(digit1);
                seg2 <= seg7(digit2);
            end
            2'b01: begin
                anodes <= 4'b1101;
                seg1 <= seg7(digit1);
                seg2 <= seg7(digit2);
            end
            default: begin
                anodes <= 4'b1111;
                seg1 <= seg7(digit1);
                seg2 <= seg7(digit2);
            end
        endcase
    end
endmodule 