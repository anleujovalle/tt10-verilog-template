module SHIFTLEFT (
    input  wire [7:0] A,
    output wire [7:0] R
);
    assign R = {A[6:0], 1'b0};
endmodule
