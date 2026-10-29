module timescalemod_leaf (
    output logic pulse
);
    initial begin
        pulse = 1'b0;
        #1;
        pulse = 1'b1;
    end
endmodule
