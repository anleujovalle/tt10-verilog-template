module tt_um_job (
    input  wire [7:0]  ui_in,     // A[7:0]
    input  wire [7:0]  uio_in,    // B[7:0]
    output wire [7:0]  uio_out,   // no usado
    output wire [7:0]  uo_out,    // resultado ALU
    input  wire        clk,
    input  wire        rst_n
);

    wire [7:0] A = ui_in;
    wire [7:0] B = uio_in;

    logic [2:0] op;            // selector de operación interno
    logic [26:0] counter = 0;  // 27 bits → hasta 134M

    // ─── Contador de 1 segundo ────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            op <= 3'b000;
        end else begin
            if (counter == 27'd99_999_999) begin
                counter <= 0;
                op <= (op == 3'd5) ? 3'd0 : op + 3'd1;  // ciclo 0→5
            end else begin
                counter <= counter + 1;
            end
        end
    end

    // ─── ALU ───────────────────────────────────────────────────
    wire [7:0] R_sum, R_sub, R_and, R_or, R_shl, R_shr;
    logic [7:0] R;

    SUMA        u_sum (.A(A), .B(B), .R(R_sum));
    RESTA       u_sub (.A(A), .B(B), .R(R_sub));
    AND_ALU     u_and (.A(A), .B(B), .R(R_and));
    OR_ALU      u_or  (.A(A), .B(B), .R(R_or));
    SHIFTLEFT   u_shl (.A(A),         .R(R_shl));
    SHIFTRIGHT  u_shr (.A(A),         .R(R_shr));

    always_comb begin
        case (op)
            3'b000: R = R_sum;
            3'b001: R = R_sub;
            3'b010: R = R_and;
            3'b011: R = R_or;
            3'b100: R = R_shl;
            3'b101: R = R_shr;
            default: R = 8'h00;
        endcase
    end

    assign uo_out = R;
    assign uio_out = 8'b0;

endmodule

