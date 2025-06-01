module suma (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output reg  [7:0] R
);
    reg [8:0] c;
    integer i;

    always @(*) begin
        c = 0;
        for (i = 0; i < 8; i = i + 1) begin
            R[i]   = A[i] ^ B[i] ^ c[i];
            c[i+1] = (A[i] & B[i]) | (A[i] & c[i]) | (B[i] & c[i]);
        end
    end
endmodule

