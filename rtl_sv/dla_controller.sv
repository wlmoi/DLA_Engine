`timescale 1ns / 1ps

// Controller FSM for one matrix multiply transaction across K MAC cycles.
module dla_controller #(
    parameter int K       = 4,
    parameter int K_IDX_W = (K <= 1) ? 1 : $clog2(K)
) (
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   start,
    output logic                   clear_pe,
    output logic                   en_pe,
    output logic [K_IDX_W-1:0]     k_idx,
    output logic                   done,
    output logic                   busy
);

    typedef enum logic [1:0] {
        S_IDLE    = 2'b00,
        S_CLEAR   = 2'b01,
        S_COMPUTE = 2'b10,
        S_DONE    = 2'b11
    } state_t;

    state_t state;
    state_t next_state;

    // Next-state logic.
    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start) begin
                    next_state = S_CLEAR;
                end
            end

            S_CLEAR: begin
                next_state = S_COMPUTE;
            end

            S_COMPUTE: begin
                if (k_idx == (K-1)) begin
                    next_state = S_DONE;
                end
            end

            S_DONE: begin
                if (!start) begin
                    next_state = S_IDLE;
                end
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // State and k-index update.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            k_idx <= '0;
        end else begin
            state <= next_state;

            if ((state == S_IDLE) || (state == S_CLEAR)) begin
                k_idx <= '0;
            end else if ((state == S_COMPUTE) && (k_idx != (K-1))) begin
                k_idx <= k_idx + 1'b1;
            end
        end
    end

    // Control outputs are purely combinational from state.
    always_comb begin
        clear_pe = (state == S_CLEAR);
        en_pe    = (state == S_COMPUTE);
        done     = (state == S_DONE);
        busy     = ((state == S_CLEAR) || (state == S_COMPUTE));
    end

endmodule
