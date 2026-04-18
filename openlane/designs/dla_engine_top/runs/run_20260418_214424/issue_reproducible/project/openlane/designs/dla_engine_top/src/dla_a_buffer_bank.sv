`timescale 1ns / 1ps

module dla_a_buffer_bank #(
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
    input  logic [K_IDX_W-1:0]           rd_col,
    output logic signed [(N*DATA_W)-1:0] row_vector
);

    logic signed [DATA_W-1:0] mem [0:N-1][0:K-1];

    integer wr_r;
    integer wr_c;
    integer i;

    always_ff @(posedge clk) begin
        if (wr_en) begin
            for (wr_r = 0; wr_r < N; wr_r = wr_r + 1) begin
                for (wr_c = 0; wr_c < K; wr_c = wr_c + 1) begin
                    if (wr_addr == ((wr_r*K) + wr_c)) begin
                        mem[wr_r][wr_c] <= wr_data;
                    end
                end
            end
        end
    end

    always_comb begin
        row_vector = '0;
        for (i = 0; i < N; i = i + 1) begin
            row_vector[(i*DATA_W) +: DATA_W] = mem[i][rd_col];
        end
    end

endmodule
