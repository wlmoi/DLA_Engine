`timescale 1ns / 1ps

module dla_pe_array #(
    parameter int N      = 4,
    parameter int DATA_W = 8,
    parameter int ACC_W  = 24
) (
    input  logic                            clk,
    input  logic                            rst_n,
    input  logic                            clear,
    input  logic                            en,
    input  logic signed [(N*DATA_W)-1:0]   a_bus,
    input  logic signed [(N*DATA_W)-1:0]   b_bus,
    output logic signed [(N*N*ACC_W)-1:0]  c_bus
);

    logic signed [DATA_W-1:0] a_vec [0:N-1];
    logic signed [DATA_W-1:0] b_vec [0:N-1];
    logic signed [ACC_W-1:0]  acc_mat [0:N-1][0:N-1];

    genvar i;
    genvar j;

    generate
        for (i = 0; i < N; i = i + 1) begin : GEN_A_UNPACK
            assign a_vec[i] = a_bus[(i*DATA_W) +: DATA_W];
        end

        for (j = 0; j < N; j = j + 1) begin : GEN_B_UNPACK
            assign b_vec[j] = b_bus[(j*DATA_W) +: DATA_W];
        end

        for (i = 0; i < N; i = i + 1) begin : GEN_PE_ROWS
            for (j = 0; j < N; j = j + 1) begin : GEN_PE_COLS
                localparam int FLAT_IDX = (i*N) + j;

                dla_pe #(
                    .DATA_W(DATA_W),
                    .ACC_W(ACC_W)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clear(clear),
                    .en(en),
                    .a_in(a_vec[i]),
                    .b_in(b_vec[j]),
                    .acc_out(acc_mat[i][j])
                );

                assign c_bus[(FLAT_IDX*ACC_W) +: ACC_W] = acc_mat[i][j];
            end
        end
    endgenerate

endmodule
