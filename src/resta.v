module RESTA (input logic [7:0] A,B, output logic [7:0] R);
    logic [8:0] c;
    always_comb begin
        c[0] = 1;                           // +1 → complemento a 2
        for (int i=0;i<8;i++) begin
         automatic logic nB = ~B[i];
            R[i]   = A[i] ^ nB ^ c[i];
            c[i+1] = (A[i]&nB) | (A[i]&c[i]) | (nB&c[i]);
        end
    end
endmodule
