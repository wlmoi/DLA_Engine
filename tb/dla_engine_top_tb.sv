`timescale 1ns / 1ps

module dla_engine_top_tb;

    localparam int N         = 4;
    localparam int K         = 4;
    localparam int DATA_W    = 8;
    localparam int ACC_W     = 24;
    localparam int AB_ADDR_W = (N*K <= 1) ? 1 : $clog2(N*K);
    localparam int C_ADDR_W  = (N*N <= 1) ? 1 : $clog2(N*N);

    logic clk;
    logic rst_n;
    logic start;

    logic wr_en;
    logic wr_sel;
    logic [AB_ADDR_W-1:0] wr_addr;
    logic signed [DATA_W-1:0] wr_data;

    logic rd_en;
    logic [C_ADDR_W-1:0] rd_addr;
    logic signed [ACC_W-1:0] rd_data;

    logic done;
    logic busy;

    integer A [0:N-1][0:K-1];
    integer B [0:K-1][0:N-1];
    integer EXP [0:N-1][0:N-1];
    integer ACT [0:N-1][0:N-1];

    integer i;
    integer j;
    integer k;
    integer test_id;
    integer total_errors;

    dla_engine_top #(
        .N(N),
        .K(K),
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .wr_en(wr_en),
        .wr_sel(wr_sel),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .done(done),
        .busy(busy)
    );

    always #5 clk = ~clk;

    task automatic write_word(input logic sel, input int addr, input int value);
        begin
            @(negedge clk);
            wr_en   <= 1'b1;
            wr_sel  <= sel;
            wr_addr <= addr[AB_ADDR_W-1:0];
            wr_data <= $signed(value);

            @(negedge clk);
            wr_en   <= 1'b0;
            wr_sel  <= 1'b0;
            wr_addr <= '0;
            wr_data <= '0;
        end
    endtask

    task automatic trigger_start;
        begin
            @(negedge clk);
            start <= 1'b1;
            @(negedge clk);
            start <= 1'b0;
        end
    endtask

    task automatic wait_done_with_timeout(input int timeout_cycles);
        int cyc;
        begin
            cyc = 0;
            while (!done && (cyc < timeout_cycles)) begin
                @(posedge clk);
                cyc = cyc + 1;
            end

            if (!done) begin
                $display("[TB][ERROR] Timeout waiting for done.");
                $fatal(1);
            end
        end
    endtask

    task automatic wait_done_drop;
        begin
            while (done) begin
                @(posedge clk);
            end
        end
    endtask

    task automatic load_matrices_from_arrays;
        begin
            for (i = 0; i < N; i = i + 1) begin
                for (k = 0; k < K; k = k + 1) begin
                    write_word(1'b0, (i*K)+k, A[i][k]);
                end
            end

            for (k = 0; k < K; k = k + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    write_word(1'b1, (k*N)+j, B[k][j]);
                end
            end
        end
    endtask

    task automatic build_expected;
        begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    EXP[i][j] = 0;
                    for (k = 0; k < K; k = k + 1) begin
                        EXP[i][j] = EXP[i][j] + (A[i][k] * B[k][j]);
                    end
                end
            end
        end
    endtask

    task automatic capture_outputs;
        begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    @(negedge clk);
                    rd_en   <= 1'b1;
                    rd_addr <= (i*N) + j;
                    #1;
                    ACT[i][j] = $signed(rd_data);
                end
            end

            @(negedge clk);
            rd_en   <= 1'b0;
            rd_addr <= '0;
        end
    endtask

    task automatic compare_outputs(input int tc_id);
        int local_errors;
        begin
            local_errors = 0;

            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    if (ACT[i][j] !== EXP[i][j]) begin
                        local_errors = local_errors + 1;
                        total_errors = total_errors + 1;
                        $display(
                            "[TB][FAIL][TC=%0d] C[%0d][%0d] actual=%0d expected=%0d",
                            tc_id, i, j, ACT[i][j], EXP[i][j]
                        );
                    end
                end
            end

            if (local_errors == 0) begin
                $display("[TB][PASS] Testcase %0d passed.", tc_id);
            end
        end
    endtask

    task automatic run_one_testcase(input int tc_id, input bit deterministic);
        begin
            if (deterministic) begin
                A[0][0] = 1;  A[0][1] = 2;  A[0][2] = 3;  A[0][3] = 4;
                A[1][0] = -1; A[1][1] = 0;  A[1][2] = 1;  A[1][3] = 2;
                A[2][0] = 2;  A[2][1] = 2;  A[2][2] = 2;  A[2][3] = 2;
                A[3][0] = 3;  A[3][1] = -3; A[3][2] = 3;  A[3][3] = -3;

                B[0][0] = 1;  B[0][1] = 0;  B[0][2] = -1; B[0][3] = 2;
                B[1][0] = 2;  B[1][1] = 1;  B[1][2] = 0;  B[1][3] = -2;
                B[2][0] = 1;  B[2][1] = 1;  B[2][2] = 1;  B[2][3] = 1;
                B[3][0] = 0;  B[3][1] = -1; B[3][2] = 2;  B[3][3] = 3;
            end else begin
                for (i = 0; i < N; i = i + 1) begin
                    for (k = 0; k < K; k = k + 1) begin
                        A[i][k] = $urandom_range(0, 15) - 8;
                    end
                end

                for (k = 0; k < K; k = k + 1) begin
                    for (j = 0; j < N; j = j + 1) begin
                        B[k][j] = $urandom_range(0, 15) - 8;
                    end
                end
            end

            load_matrices_from_arrays();
            build_expected();
            trigger_start();
            wait_done_with_timeout(200);
            capture_outputs();
            compare_outputs(tc_id);
            wait_done_drop();
        end
    endtask

    initial begin
        $dumpfile("sim/results/dla_engine_top_tb.vcd");
        $dumpvars(0, dla_engine_top_tb);

        clk          = 1'b0;
        rst_n        = 1'b0;
        start        = 1'b0;
        wr_en        = 1'b0;
        wr_sel       = 1'b0;
        wr_addr      = '0;
        wr_data      = '0;
        rd_en        = 1'b0;
        rd_addr      = '0;
        total_errors = 0;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        run_one_testcase(0, 1'b1);

        for (test_id = 1; test_id <= 10; test_id = test_id + 1) begin
            run_one_testcase(test_id, 1'b0);
        end

        if (total_errors == 0) begin
            $display("[TB][SUCCESS] All testcases passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] Total mismatches = %0d", total_errors);
            $fatal(1);
        end
    end

endmodule
