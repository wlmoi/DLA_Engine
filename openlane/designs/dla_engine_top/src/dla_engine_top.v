`timescale 1ns / 1ps

// Top-level DLA engine:
// - Loads A and B matrix elements through a shared write port.
// - Runs controller-driven PE accumulation across K cycles.
// - Exposes C matrix elements through a read address/data interface.
module dla_engine_top #(
    parameter N         = 4,
    parameter K         = 4,
    parameter DATA_W    = 8,
    parameter ACC_W     = 24,
    parameter AB_ADDR_W = (N*K <= 1) ? 1 : $clog2(N*K),
    parameter C_ADDR_W  = (N*N <= 1) ? 1 : $clog2(N*N),
    parameter K_IDX_W   = (K <= 1) ? 1 : $clog2(K)
) (
    input                            clk,
    input                            rst_n,
    input                            start,

    input                            wr_en,
    input                            wr_sel,
    input [AB_ADDR_W-1:0]            wr_addr,
    input signed [DATA_W-1:0]        wr_data,

    input                            rd_en,
    input [C_ADDR_W-1:0]             rd_addr,
    output reg signed [ACC_W-1:0]    rd_data,

    output                           done,
    output                           busy
);

    wire clear_pe;
    wire en_pe;
    wire [K_IDX_W-1:0] k_idx;

    wire signed [(N*DATA_W)-1:0] a_row_vector;
    wire signed [(N*DATA_W)-1:0] b_col_vector;
    wire signed [(N*N*ACC_W)-1:0] c_bus;

    dla_controller #(
        .K(K),
        .K_IDX_W(K_IDX_W)
    ) u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .clear_pe(clear_pe),
        .en_pe(en_pe),
        .k_idx(k_idx),
        .done(done),
        .busy(busy)
    );

    dla_a_buffer_bank #(
        .N(N),
        .K(K),
        .DATA_W(DATA_W),
        .ADDR_W(AB_ADDR_W),
        .K_IDX_W(K_IDX_W)
    ) u_a_buffer (
        .clk(clk),
        .wr_en(wr_en && !wr_sel),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_col(k_idx),
        .row_vector(a_row_vector)
    );

    dla_b_buffer_bank #(
        .N(N),
        .K(K),
        .DATA_W(DATA_W),
        .ADDR_W(AB_ADDR_W),
        .K_IDX_W(K_IDX_W)
    ) u_b_buffer (
        .clk(clk),
        .wr_en(wr_en && wr_sel),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_row(k_idx),
        .col_vector(b_col_vector)
    );

    dla_pe_array #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) u_pe_array (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear_pe),
        .en(en_pe),
        .a_bus(a_row_vector),
        .b_bus(b_col_vector),
        .c_bus(c_bus)
    );

    // Addressed combinational read from computed C matrix.
    always @* begin
        rd_data = {ACC_W{1'b0}};
        if (rd_en) begin
            rd_data = c_bus[(rd_addr*ACC_W) +: ACC_W];
        end
    end

endmodule
