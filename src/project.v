/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
module tt_um_job (
    input  logic        clk,          // W5 - 100 MHz
    input  logic [15:0] sw,           // switches
    input  logic [4:0]  btn,          // {D,R,L,U,C} = [4:0]
    output logic [15:0] led,          // leds = switches
    input  wire       ena,       // <--- ESTE ES EL QUE TE FALTA
    output logic [6:0]  seg,          // segmentos (activo bajo)
    output logic [3:0]  an,           // dígitos   (activo bajo)
    output logic        dp            // punto decimal
);

    // ---------- anti-rebote -----------------------------------------
    logic [4:0] q1, q2;
    always_ff @(posedge clk) begin
        q1 <= btn;
        q2 <= q1;
    end
    wire [4:0] pulse = q1 & ~q2;      // pulso 1-tick

    // ---------- selector de operación -------------------------------
    typedef enum logic [2:0]
        {SUM=0, SUB=1, A_AND=2, A_OR=3, SHL=4, SHR=5} op_t;

    op_t  sel = SUM;
    logic shift_dir = 1'b0;           // 0=SHL 1=SHR

    always_ff @(posedge clk) begin
        if      (pulse[0]) sel <= SUM;           // Center
        else if (pulse[1]) sel <= SUB;           // Up
        else if (pulse[2]) sel <= A_AND;         // Left
        else if (pulse[3]) sel <= A_OR;          // Right
        else if (pulse[4]) begin                // Down → alterna shifts
            shift_dir <= ~shift_dir;
            sel <= shift_dir ? SHR : SHL;
        end
    end

    // ---------- ALU de 8 bits ---------------------------------------
    logic [7:0] A = sw[7:0];
    logic [7:0] B = sw[15:8];

    logic [7:0] R_sum, R_sub, R_and, R_or, R_shl, R_shr;

    SUMA        u_sum (.A(A), .B(B), .R(R_sum));
    RESTA       u_sub (.A(A), .B(B), .R(R_sub));
    AND_ALU     u_and (.A(A), .B(B), .R(R_and));
    OR_ALU      u_or  (.A(A), .B(B), .R(R_or));
    SHIFTLEFT   u_shl (.A(A),         .R(R_shl));
    SHIFTRIGHT  u_shr (.A(A),         .R(R_shr));

    logic [7:0] R;
    always_comb unique case (sel)
        SUM    : R = R_sum;
        SUB    : R = R_sub;
        A_AND  : R = R_and;
        A_OR   : R = R_or;
        SHL    : R = R_shl;
        SHR    : R = R_shr;
        default: R = 8'h00;
    endcase

    // ---------- LEDs = switches -------------------------------------
    assign led = sw;

    // ---------- Display ---------------------------------------------
    Display8bits disp (
        .clk   (clk),
        .value (R),
        .seg   (seg),
        .an    (an),
        .dp    (dp)
    );
endmodule


// ====================================================================
//  ALU modules - solo compuertas
// ====================================================================
module SUMA (input logic [7:0] A,B, output logic [7:0] R);
    logic [8:0] c;
    always_comb begin
        c[0] = 0;
        for (int i=0;i<8;i++) begin
            R[i]   = A[i] ^ B[i] ^ c[i];
            c[i+1] = (A[i]&B[i]) | (A[i]&c[i]) | (B[i]&c[i]);
        end
    end
endmodule

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

module AND_ALU (input logic [7:0] A,B, output logic [7:0] R);
    assign R = A & B;
endmodule

module OR_ALU  (input logic [7:0] A,B, output logic [7:0] R);
    assign R = A | B;
endmodule

module SHIFTLEFT  (input logic [7:0] A, output logic [7:0] R);
    assign R = {A[6:0],1'b0};
endmodule

module SHIFTRIGHT (input logic [7:0] A, output logic [7:0] R);
    assign R = {1'b0,A[7:1]};
endmodule


// ====================================================================
//  Display8bits - byte (0-255) → 4 dígitos decimales   Basys-3
// ====================================================================
module Display8bits (
    input  logic        clk,          // 100 MHz
    input  logic [7:0]  value,
    output logic [6:0]  seg,          // activo bajo
    output logic [3:0]  an,           // activo bajo
    output logic        dp
);
    // --- binario → BCD ---------------------------------------------
    logic [3:0] d0, d1, d2, d3;
    always_comb begin
      automatic int n = value;        // 32 bit signed, OK en SV
        d3 = 0;
        d2 = n / 100;
        n  = n % 100;
        d1 = n / 10;
        d0 = n % 10;
    end

    // --- multiplexor de dígitos ------------------------------------
    logic [15:0] div = 0;
    always_ff @(posedge clk) div <= div + 1;

    logic [1:0] sel = div[15:14];
    logic [3:0] cur;
    always_comb case(sel)
        2'd0: cur = d0;
        2'd1: cur = d1;
        2'd2: cur = d2;
        2'd3: cur = d3;
    endcase

    logic [3:0] an_n = ~(4'b0001 << sel);   // activo bajo

    // --- decodificador 0-9 → 7-seg (activo bajo) --------------------
    logic [6:0] seg_n;
    always_comb unique case(cur)
        4'd0: seg_n = 7'b1000000;
        4'd1: seg_n = 7'b1111001;
        4'd2: seg_n = 7'b0100100;
        4'd3: seg_n = 7'b0110000;
        4'd4: seg_n = 7'b0011001;
        4'd5: seg_n = 7'b0010010;
        4'd6: seg_n = 7'b0000010;
        4'd7: seg_n = 7'b1111000;
        4'd8: seg_n = 7'b0000000;
        4'd9: seg_n = 7'b0010000;
        default: seg_n = 7'b1111111;   // blank
    endcase

    // --- REGISTROS de salida  (único driver) ------------------------
    always_ff @(posedge clk) begin
        seg <= seg_n;
        an  <= an_n;
    end

    assign dp = 1'b1;      // punto decimal apagado
endmodule
