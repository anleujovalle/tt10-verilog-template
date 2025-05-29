module SHIFTRIGHT (input logic [7:0] A, output logic [7:0] R);
    assign R = {1'b0,A[7:1]};
endmodule
