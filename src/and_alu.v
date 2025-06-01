module AND_ALU (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] R
);
    assign R = A & B;
endmodule
