`timescale 1ns / 1ps

module dla_pe_tb;

    localparam int DATA_W = 8;
    localparam int ACC_W  = 24;

    logic                     clk;
    logic                     rst_n;
    logic                     clear;
    logic                     en;
    logic signed [DATA_W-1:0] a_in;
    logic signed [DATA_W-1:0] b_in;
    logic signed [ACC_W-1:0]  acc_out;

    integer errors;

    dla_pe #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .en(en),
        .a_in(a_in),
        .b_in(b_in),
        .acc_out(acc_out)
    );

    always #5 clk = ~clk;

    task automatic apply_cycle(
        input logic clear_i,
        input logic en_i,
        input int a_i,
        input int b_i
    );
        begin
            @(negedge clk);
            clear <= clear_i;
            en    <= en_i;
            a_in  <= $signed(a_i);
            b_in  <= $signed(b_i);
            @(posedge clk);
            #1;
        end
    endtask

    task automatic expect_acc(input int step_id, input int expected);
        begin
            if ($signed(acc_out) !== expected) begin
                errors = errors + 1;
                $display(
                    "[TB][FAIL][step=%0d] acc_out=%0d expected=%0d",
                    step_id,
                    $signed(acc_out),
                    expected
                );
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/dla_pe_tb.vcd");
        $dumpvars(0, dla_pe_tb);

        clk    = 1'b0;
        rst_n  = 1'b0;
        clear  = 1'b0;
        en     = 1'b0;
        a_in   = '0;
        b_in   = '0;
        errors = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        #1;
        expect_acc(0, 0);

        apply_cycle(1'b1, 1'b1, 5, 6);   // clear has priority over accumulate
        expect_acc(1, 0);

        apply_cycle(1'b0, 1'b1, 2, 3);   // +6
        expect_acc(2, 6);

        apply_cycle(1'b0, 1'b1, -4, 2);  // -8, total = -2
        expect_acc(3, -2);

        apply_cycle(1'b0, 1'b0, 7, 7);   // hold value
        expect_acc(4, -2);

        apply_cycle(1'b1, 1'b0, 0, 0);   // clear
        expect_acc(5, 0);

        if (errors == 0) begin
            $display("[TB][PASS] dla_pe_tb passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] dla_pe_tb mismatches=%0d", errors);
            $fatal(1);
        end
    end

endmodule
