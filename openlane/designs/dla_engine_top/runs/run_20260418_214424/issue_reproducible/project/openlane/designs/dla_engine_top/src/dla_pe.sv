`timescale 1ns / 1ps

module dla_pe #(
    parameter int DATA_W = 8,
    parameter int ACC_W  = 24
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     clear,
    input  logic                     en,
    input  logic signed [DATA_W-1:0] a_in,
    input  logic signed [DATA_W-1:0] b_in,
    output logic signed [ACC_W-1:0]  acc_out
);

    logic signed [(2*DATA_W)-1:0] mult_res;
    logic signed [ACC_W-1:0]      mult_ext;

    assign mult_res = a_in * b_in;
    assign mult_ext = {{(ACC_W-(2*DATA_W)){mult_res[(2*DATA_W)-1]}}, mult_res};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out <= '0;
        end else if (clear) begin
            acc_out <= '0;
        end else if (en) begin
            acc_out <= acc_out + mult_ext;
        end
    end

endmodule
