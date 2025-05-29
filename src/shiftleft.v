module SHIFTLEFT  (input logic [7:0] A, output logic [7:0] R);
    assign R = {A[6:0],1'b0};
endmodule
