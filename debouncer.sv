module debouncer (
    input wire clk,
    input wire btn_in,
    output reg btn_out
);
    reg [19:0] counter;
    reg btn_sync;
    
    always @(posedge clk) begin
        btn_sync <= btn_in;
        if (btn_sync ^ btn_out) begin
            counter <= counter + 1;
            if (&counter) btn_out <= btn_sync;
        end else begin
            counter <= 0;
        end
    end
endmodule 