`timescale 1ns / 1ps

// B buffer stores matrix B as [k][col] and returns a full k-row at rd_row=k.
module dla_b_buffer_bank #(
    parameter N       = 4,
    parameter K       = 4,
    parameter DATA_W  = 8,
    parameter ADDR_W  = (N*K <= 1) ? 1 : $clog2(N*K),
    parameter K_IDX_W = (K <= 1) ? 1 : $clog2(K)
) (
    input                            clk,
    input                            wr_en,
    input [ADDR_W-1:0]               wr_addr,
    input signed [DATA_W-1:0]        wr_data,
    input [K_IDX_W-1:0]              rd_row,
    output reg signed [(N*DATA_W)-1:0] col_vector
);

    reg signed [DATA_W-1:0] mem [0:(N*K)-1];

    integer j;

    // Single-port synchronous write using linearized row-major addressing.
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Combinational read: gather B[rd_row][0..N-1] into col_vector.
    always @* begin
        col_vector = {(N*DATA_W){1'b0}};
        for (j = 0; j < N; j = j + 1) begin
            col_vector[(j*DATA_W) +: DATA_W] = mem[(rd_row*N) + j];
        end
    end

endmodule
