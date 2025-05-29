module suma (input logic [7:0] A,B, output logic [7:0] R);
    logic [8:0] c;
    always_comb begin
        c[0] = 0;
        for (int i=0;i<8;i++) begin
            R[i]   = A[i] ^ B[i] ^ c[i];
            c[i+1] = (A[i]&B[i]) | (A[i]&c[i]) | (B[i]&c[i]);
        end
    end
endmodule
