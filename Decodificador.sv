module Decodificador (
    input wire [3:0] binario,    // Entrada de 4 bits en binario
    output wire [3:0] gray_code, // Salida en código Gray
    output wire [6:0] display1,  // Display de unidades (0-9)
    output wire [6:0] display2   // Display de decenas (0 o 1)
);

//Conversión binario a Gray
assign gray_code = {binario[3], 
                   binario[3] ^ binario[2], 
                   binario[2] ^ binario[1], 
                   binario[1] ^ binario[0]};
/*
 * Tabla de verdad para conversión binario a Gray:
 * Binario | Gray
 * -----------------
 *  0000   | 0000
 *  0001   | 0001
 *  0010   | 0011
 *  0011   | 0010
 *  0100   | 0110
 *  0101   | 0111
 *  0110   | 0101
 *  0111   | 0100
 *  1000   | 1100
 *  1001   | 1101
 *  1010   | 1111
 *  1011   | 1110
 *  1100   | 1010
 *  1101   | 1011
 *  1110   | 1001
 *  1111   | 1000
 */

// Conversión Gray a decimal mediante fórmula matemática
wire [4:0] valor_gray;
assign valor_gray = {1'b0, gray_code[3], 
                    gray_code[3] ^ gray_code[2], 
                    gray_code[3] ^ gray_code[2] ^ gray_code[1], 
                    gray_code[3] ^ gray_code[2] ^ gray_code[1] ^ gray_code[0]};

// Separación en decenas y unidades
wire [3:0] unidades = valor_gray[3:0] % 10;  // Unidades mediante módulo
wire [3:0] decenas = valor_gray[3:0] / 10;   // Decenas mediante división

// Decodificador a 7 segmentos 
function [6:0] decodificar_7segmentos(input [3:0] num);
    begin
        case (num)
            4'd0: decodificar_7segmentos = 7'b1000000; // 0
            4'd1: decodificar_7segmentos = 7'b1111001; // 1
            4'd2: decodificar_7segmentos = 7'b0100100; // 2
            4'd3: decodificar_7segmentos = 7'b0110000; // 3
            4'd4: decodificar_7segmentos = 7'b0011001; // 4
            4'd5: decodificar_7segmentos = 7'b0010010; // 5
            4'd6: decodificar_7segmentos = 7'b0000010; // 6
            4'd7: decodificar_7segmentos = 7'b1111000; // 7
            4'd8: decodificar_7segmentos = 7'b0000000; // 8
            4'd9: decodificar_7segmentos = 7'b0010000; // 9
            default: decodificar_7segmentos = 7'b0111111; // -
        endcase
    end
endfunction

// Asignación de salidas
assign display1 = decodificar_7segmentos(unidades);
assign display2 = (decenas != 0) ? decodificar_7segmentos(decenas) : 7'b1111111;

endmodule 