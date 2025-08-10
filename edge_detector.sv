module edge_detector (
    input wire clk,
    input wire signal_in,
    output wire rising_edge
);
    reg [1:0] sync_reg;
    
    always @(posedge clk) begin
        sync_reg <= {sync_reg[0], signal_in};
    end
    
    assign rising_edge = (sync_reg == 2'b01);
endmodule