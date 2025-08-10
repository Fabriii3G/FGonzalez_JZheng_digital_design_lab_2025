module edge_detector (
    input wire clk,
    input wire signal_in,
    output wire rising_edge
);
    reg [1:0] sync;
    
    always @(posedge clk) begin
        sync <= {sync[0], signal_in};
    end
    
    assign rising_edge = (sync == 2'b01);
endmodule 