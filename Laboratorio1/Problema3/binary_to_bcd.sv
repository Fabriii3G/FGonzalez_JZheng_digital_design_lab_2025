module binary_to_bcd (
    input wire [5:0] binary,
    output reg [3:0] bcd0,  // Unidades
    output reg [3:0] bcd1   // Decenas
);
    always @(*) begin
        if (binary < 10) begin
            bcd1 = 4'd0;
            bcd0 = binary[3:0];
        end else begin
            bcd1 = binary / 10;
            bcd0 = binary % 10;
        end
    end
endmodule 