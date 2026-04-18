`timescale 1ns / 1ps

module dla_pe_array_tb;

    localparam int N      = 2;
    localparam int DATA_W = 8;
    localparam int ACC_W  = 24;

    logic                           clk;
    logic                           rst_n;
    logic                           clear;
    logic                           en;
    logic signed [(N*DATA_W)-1:0]   a_bus;
    logic signed [(N*DATA_W)-1:0]   b_bus;
    logic signed [(N*N*ACC_W)-1:0]  c_bus;

    integer errors;

    dla_pe_array #(
        .N(N),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .en(en),
        .a_bus(a_bus),
        .b_bus(b_bus),
        .c_bus(c_bus)
    );

    always #5 clk = ~clk;

    task automatic drive_cycle(
        input logic clear_i,
        input logic en_i,
        input logic signed [(N*DATA_W)-1:0] a_i,
        input logic signed [(N*DATA_W)-1:0] b_i
    );
        begin
            @(negedge clk);
            clear <= clear_i;
            en    <= en_i;
            a_bus <= a_i;
            b_bus <= b_i;
            @(posedge clk);
            #1;
        end
    endtask

    function automatic integer c_at(input int row, input int col);
        int flat_idx;
        begin
            flat_idx = (row*N) + col;
            c_at = $signed(c_bus[(flat_idx*ACC_W) +: ACC_W]);
        end
    endfunction

    task automatic expect_c(input int row, input int col, input int expected);
        integer actual;
        begin
            actual = c_at(row, col);
            if (actual !== expected) begin
                errors = errors + 1;
                $display(
                    "[TB][FAIL] C[%0d][%0d]=%0d expected=%0d",
                    row,
                    col,
                    actual,
                    expected
                );
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/dla_pe_array_tb.vcd");
        $dumpvars(0, dla_pe_array_tb);

        clk    = 1'b0;
        rst_n  = 1'b0;
        clear  = 1'b0;
        en     = 1'b0;
        a_bus  = '0;
        b_bus  = '0;
        errors = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // Reset accumulators once before compute.
        drive_cycle(1'b1, 1'b0, '0, '0);

        // Cycle 0: a=[1,2], b=[3,4]
        drive_cycle(1'b0, 1'b1, {8'sd2, 8'sd1}, {8'sd4, 8'sd3});

        // Cycle 1: a=[-1,0], b=[2,-2]
        drive_cycle(1'b0, 1'b1, {8'sd0, -8'sd1}, {-8'sd2, 8'sd2});

        // Cycle 2: a=[3,1], b=[1,5]
        drive_cycle(1'b0, 1'b1, {8'sd1, 8'sd3}, {8'sd5, 8'sd1});

        // Hold for one cycle and check final accumulators.
        drive_cycle(1'b0, 1'b0, '0, '0);

        // Expected matrix:
        // [ 4, 21 ]
        // [ 7, 13 ]
        expect_c(0, 0, 4);
        expect_c(0, 1, 21);
        expect_c(1, 0, 7);
        expect_c(1, 1, 13);

        if (errors == 0) begin
            $display("[TB][PASS] dla_pe_array_tb passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] dla_pe_array_tb mismatches=%0d", errors);
            $fatal(1);
        end
    end

endmodule
