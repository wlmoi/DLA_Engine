`timescale 1ns / 1ps

module dla_b_buffer_bank #(
    parameter int N       = 4,
    parameter int K       = 4,
    parameter int DATA_W  = 8,
    parameter int ADDR_W  = (N*K <= 1) ? 1 : $clog2(N*K),
    parameter int K_IDX_W = (K <= 1) ? 1 : $clog2(K)
) (
    input  logic                         clk,
    input  logic                         wr_en,
    input  logic [ADDR_W-1:0]            wr_addr,
    input  logic signed [DATA_W-1:0]     wr_data,
    input  logic [K_IDX_W-1:0]           rd_row,
    output logic signed [(N*DATA_W)-1:0] col_vector
);

    logic signed [DATA_W-1:0] mem [0:K-1][0:N-1];

    integer wr_r;
    integer wr_c;
    integer j;

    always_ff @(posedge clk) begin
        if (wr_en) begin
            for (wr_r = 0; wr_r < K; wr_r = wr_r + 1) begin
                for (wr_c = 0; wr_c < N; wr_c = wr_c + 1) begin
                    if (wr_addr == ((wr_r*N) + wr_c)) begin
                        mem[wr_r][wr_c] <= wr_data;
                    end
                end
            end
        end
    end

    always_comb begin
        col_vector = '0;
        for (j = 0; j < N; j = j + 1) begin
            col_vector[(j*DATA_W) +: DATA_W] = mem[rd_row][j];
        end
    end

endmodule
