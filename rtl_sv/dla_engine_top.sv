`timescale 1ns / 1ps

// Top-level DLA engine:
// - Loads A and B matrix elements through a shared write port.
// - Runs controller-driven PE accumulation across K cycles.
// - Exposes C matrix elements through a read address/data interface.
module dla_engine_top #(
    parameter int N         = 4,
    parameter int K         = 4,
    parameter int DATA_W    = 8,
    parameter int ACC_W     = 24,
    parameter int AB_ADDR_W = (N*K <= 1) ? 1 : $clog2(N*K),
    parameter int C_ADDR_W  = (N*N <= 1) ? 1 : $clog2(N*N),
    parameter int K_IDX_W   = (K <= 1) ? 1 : $clog2(K)
) (
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic                      start,

    input  logic                      wr_en,
    input  logic                      wr_sel,
    input  logic [AB_ADDR_W-1:0]      wr_addr,
    input  logic signed [DATA_W-1:0]  wr_data,

    input  logic                      rd_en,
    input  logic [C_ADDR_W-1:0]       rd_addr,
    output logic signed [ACC_W-1:0]   rd_data,

    output logic                      done,
    output logic                      busy
);

    localparam int C_DEPTH = N*N;

    logic clear_pe;
    logic en_pe;
    logic [K_IDX_W-1:0] k_idx;

    logic signed [(N*DATA_W)-1:0] a_row_vector;
    logic signed [(N*DATA_W)-1:0] b_col_vector;
    logic signed [(N*N*ACC_W)-1:0] c_bus;
    logic signed [ACC_W-1:0] c_vec [0:C_DEPTH-1];
    integer rd_i;

    // Flattened C bus unpacking for addressable readback.
    genvar c_idx;
    generate
        for (c_idx = 0; c_idx < C_DEPTH; c_idx = c_idx + 1) begin : GEN_C_UNPACK
            assign c_vec[c_idx] = c_bus[(c_idx*ACC_W) +: ACC_W];
        end
    endgenerate

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
    always_comb begin
        rd_data = '0;
        if (rd_en) begin
            for (rd_i = 0; rd_i < C_DEPTH; rd_i = rd_i + 1) begin
                if (rd_addr == rd_i) begin
                    rd_data = c_vec[rd_i];
                end
            end
        end
    end

endmodule
