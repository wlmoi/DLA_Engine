`timescale 1ns / 1ps

module dla_b_buffer_bank_tb;

    localparam int N       = 3;
    localparam int K       = 4;
    localparam int DATA_W  = 8;
    localparam int ADDR_W  = (N*K <= 1) ? 1 : $clog2(N*K);
    localparam int K_IDX_W = (K <= 1) ? 1 : $clog2(K);

    logic                         clk;
    logic                         wr_en;
    logic [ADDR_W-1:0]            wr_addr;
    logic signed [DATA_W-1:0]     wr_data;
    logic [K_IDX_W-1:0]           rd_row;
    logic signed [(N*DATA_W)-1:0] col_vector;

    integer B [0:K-1][0:N-1];
    integer errors;
    integer r;
    integer c;

    dla_b_buffer_bank #(
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
        .rd_row(rd_row),
        .col_vector(col_vector)
    );

    always #5 clk = ~clk;

    task automatic write_b(input int row, input int col, input int value);
        begin
            @(negedge clk);
            wr_en   <= 1'b1;
            wr_addr <= ((row*N) + col);
            wr_data <= $signed(value);

            @(negedge clk);
            wr_en   <= 1'b0;
            wr_addr <= '0;
            wr_data <= '0;
        end
    endtask

    function automatic integer lane_value(input int lane_idx);
        begin
            lane_value = $signed(col_vector[(lane_idx*DATA_W) +: DATA_W]);
        end
    endfunction

    initial begin
        $dumpfile("sim/results/dla_b_buffer_bank_tb.vcd");
        $dumpvars(0, dla_b_buffer_bank_tb);

        clk     = 1'b0;
        wr_en   = 1'b0;
        wr_addr = '0;
        wr_data = '0;
        rd_row  = '0;
        errors  = 0;

        B[0][0] = 1;  B[0][1] = -1; B[0][2] = 2;
        B[1][0] = 3;  B[1][1] = 4;  B[1][2] = -5;
        B[2][0] = -2; B[2][1] = 6;  B[2][2] = 7;
        B[3][0] = 8;  B[3][1] = -3; B[3][2] = 0;

        for (r = 0; r < K; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                write_b(r, c, B[r][c]);
            end
        end

        for (r = 0; r < K; r = r + 1) begin
            rd_row = r[K_IDX_W-1:0];
            #1;

            for (c = 0; c < N; c = c + 1) begin
                if (lane_value(c) !== B[r][c]) begin
                    errors = errors + 1;
                    $display(
                        "[TB][FAIL] rd_row=%0d lane=%0d value=%0d expected=%0d",
                        r,
                        c,
                        lane_value(c),
                        B[r][c]
                    );
                end
            end

            @(posedge clk);
        end

        if (errors == 0) begin
            $display("[TB][PASS] dla_b_buffer_bank_tb passed.");
            $finish;
        end else begin
            $display("[TB][ERROR] dla_b_buffer_bank_tb mismatches=%0d", errors);
            $fatal(1);
        end
    end

endmodule
