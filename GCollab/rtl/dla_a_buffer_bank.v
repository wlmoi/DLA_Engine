`timescale 1ns / 1ps

// A buffer stores matrix A as [row][k] and returns a full row-vector at rd_col=k.
module dla_a_buffer_bank #(
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
    input [K_IDX_W-1:0]              rd_col,
    output reg signed [(N*DATA_W)-1:0] row_vector
);

    reg signed [DATA_W-1:0] mem [0:(N*K)-1];

    integer i;

    // Single-port synchronous write using linearized row-major addressing.
    always @(posedge clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // Combinational read: gather A[0..N-1][rd_col] into row_vector.
    always @* begin
        row_vector = {(N*DATA_W){1'b0}};
        for (i = 0; i < N; i = i + 1) begin
            row_vector[(i*DATA_W) +: DATA_W] = mem[(i*K) + rd_col];
        end
    end

endmodule
