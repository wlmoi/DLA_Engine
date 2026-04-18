`timescale 1ns / 1ps

module dla_controller_tb;

    localparam int K       = 4;
    localparam int K_IDX_W = (K <= 1) ? 1 : $clog2(K);

    logic               clk;
    logic               rst_n;
    logic               start;
    logic               clear_pe;
    logic               en_pe;
    logic [K_IDX_W-1:0] k_idx;
    logic               done;
    logic               busy;

    integer errors;
    integer clear_count;
    integer en_count;
    integer done_count;
    integer expected_k;

    dla_controller #(
        .K(K),
        .K_IDX_W(K_IDX_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .clear_pe(clear_pe),
        .en_pe(en_pe),
        .k_idx(k_idx),
        .done(done),
        .busy(busy)
    );

    always #5 clk = ~clk;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clear_count <= 0;
            en_count    <= 0;
            done_count  <= 0;
            expected_k  <= 0;
        end else begin
            if (clear_pe) begin
                clear_count <= clear_count + 1;
            end

            if (en_pe) begin
                if (k_idx !== expected_k[K_IDX_W-1:0]) begin
                    errors <= errors + 1;
                    $display(
                        "[TB][FAIL] k_idx=%0d expected=%0d",
                        k_idx,
                        expected_k[K_IDX_W-1:0]
                    );
                end
                expected_k <= expected_k + 1;
                en_count   <= en_count + 1;
            end

            if (done) begin
                done_count <= done_count + 1;
            end
        end
    end

    task automatic pulse_start;
        begin
            @(negedge clk);
            start <= 1'b1;
            @(negedge clk);
            start <= 1'b0;
        end
    endtask

    task automatic run_transaction(input int txn_id);
        integer timeout;
        begin
            clear_count = 0;
            en_count    = 0;
            done_count  = 0;
            expected_k  = 0;

            pulse_start();

            timeout = 0;
            while (!done && (timeout < 40)) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (!done) begin
                errors = errors + 1;
                $display("[TB][FAIL][txn=%0d] timeout waiting for done", txn_id);
            end

            @(posedge clk);

            if (clear_count != 1) begin
                errors = errors + 1;
                $display("[TB][FAIL][txn=%0d] clear_count=%0d expected=1", txn_id, clear_count);
            end

            if (en_count != K) begin
                errors = errors + 1;
                $display("[TB][FAIL][txn=%0d] en_count=%0d expected=%0d", txn_id, en_count, K);
            end

            if (done_count < 1) begin
                errors = errors + 1;
                $display("[TB][FAIL][txn=%0d] done never asserted", txn_id);
            end

            if (busy) begin
                errors = errors + 1;
                $display("[TB][FAIL][txn=%0d] busy should deassert after done", txn_id);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/results/dla_controller_tb.vcd");
        $dumpvars(0, dla_controller_tb);

        clk         = 1'b0;
        rst_n       = 1'b0;
        start       = 1'b0;
        errors      = 0;
        clear_count = 0;
        en_count    = 0;
        done_count  = 0;
        expected_k  = 0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_transaction(0);
        run_transaction(1);

        if (errors == 0) begin
            $display("[TB][PASS] dla_controller_tb passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] dla_controller_tb mismatches=%0d", errors);
            $fatal(1);
        end
    end

endmodule
