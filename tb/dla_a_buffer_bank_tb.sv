`timescale 1ns / 1ps

module dla_a_buffer_bank_tb;

    localparam int N       = 3;
    localparam int K       = 4;
    localparam int DATA_W  = 8;
    localparam int ADDR_W  = (N*K <= 1) ? 1 : $clog2(N*K);
    localparam int K_IDX_W = (K <= 1) ? 1 : $clog2(K);

    logic                         clk;
    logic                         wr_en;
    logic [ADDR_W-1:0]            wr_addr;
    logic signed [DATA_W-1:0]     wr_data;
    logic [K_IDX_W-1:0]           rd_col;
    logic signed [(N*DATA_W)-1:0] row_vector;

    integer A [0:N-1][0:K-1];
    integer errors;
    integer i;
    integer k;

    dla_a_buffer_bank #(
        .N(N),
        .K(K),
        .DATA_W(DATA_W),
        .ADDR_W(ADDR_W),
        .K_IDX_W(K_IDX_W)
    ) dut (
        .clk(clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_col(rd_col),
        .row_vector(row_vector)
    );

    always #5 clk = ~clk;

    task automatic write_a(input int row, input int col, input int value);
        begin
            @(negedge clk);
            wr_en   <= 1'b1;
            wr_addr <= ((row*K) + col);
            wr_data <= $signed(value);

            @(negedge clk);
            wr_en   <= 1'b0;
            wr_addr <= '0;
            wr_data <= '0;
        end
    endtask

    function automatic integer lane_value(input int lane_idx);
        begin
            lane_value = $signed(row_vector[(lane_idx*DATA_W) +: DATA_W]);
        end
    endfunction

    initial begin
        $dumpfile("sim/results/dla_a_buffer_bank_tb.vcd");
        $dumpvars(0, dla_a_buffer_bank_tb);

        clk    = 1'b0;
        wr_en  = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        rd_col  = '0;
        errors  = 0;

        A[0][0] = 1;  A[0][1] = -2; A[0][2] = 3;  A[0][3] = -4;
        A[1][0] = 5;  A[1][1] = 6;  A[1][2] = -7; A[1][3] = 8;
        A[2][0] = -1; A[2][1] = 2;  A[2][2] = -3; A[2][3] = 4;

        for (i = 0; i < N; i = i + 1) begin
            for (k = 0; k < K; k = k + 1) begin
                write_a(i, k, A[i][k]);
            end
        end

        for (k = 0; k < K; k = k + 1) begin
            rd_col = k[K_IDX_W-1:0];
            #1;

            for (i = 0; i < N; i = i + 1) begin
                if (lane_value(i) !== A[i][k]) begin
                    errors = errors + 1;
                    $display(
                        "[TB][FAIL] rd_col=%0d lane=%0d value=%0d expected=%0d",
                        k,
                        i,
                        lane_value(i),
                        A[i][k]
                    );
                end
            end

            @(posedge clk);
        end

        if (errors == 0) begin
            $display("[TB][PASS] dla_a_buffer_bank_tb passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] dla_a_buffer_bank_tb mismatches=%0d", errors);
            $fatal(1);
        end
    end

endmodule
