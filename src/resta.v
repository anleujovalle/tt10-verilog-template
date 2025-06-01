module RESTA (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output reg  [7:0] R
);
    reg [8:0] c;
    reg nB;
    integer i;

    always @(*) begin
        c = 0;
        c[0] = 1;  // complemento a 2
        for (i = 0; i < 8; i = i + 1) begin
            nB = ~B[i];
            R[i]   = A[i] ^ nB ^ c[i];
            c[i+1] = (A[i] & nB) | (A[i] & c[i]) | (nB & c[i]);
        end
    end
endmodule
