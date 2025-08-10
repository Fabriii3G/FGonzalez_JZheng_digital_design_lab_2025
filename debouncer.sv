module debouncer (
    input wire clk,
    input wire btn_in,
    output wire btn_out
);
    parameter DEBOUNCE_MS = 20;       // 20 ms de debounce
    parameter CLK_FREQ_MHZ = 50;      // Frecuencia de reloj en MHz
    
    localparam COUNTER_MAX = DEBOUNCE_MS * CLK_FREQ_MHZ * 1000;
    
    reg [31:0] counter = 0;
    reg btn_state = 0;
    
    always @(posedge clk) begin
        if (btn_in != btn_state) begin
            btn_state <= btn_in;
            counter <= 0;
        end else if (counter < COUNTER_MAX) begin
            counter <= counter + 1;
        end else begin
            btn_out <= btn_state;
        end
    end
endmodule