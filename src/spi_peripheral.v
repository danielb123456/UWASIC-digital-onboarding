/*
 * Copyright (c) 2026 Daniel Bondar
 * SPDX-License-Identifier: Apache-2.0
 */

module spi_peripheral (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] ui_in, // copi 1, ncs 2, sclk 0

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

    // initial values
    wire new_copi = ui_in[1];
    wire new_ncs = ui_in[2];
    wire new_sclk = ui_in[0];

    // needed for stable flip flop clocks
    reg [1:0] sclk_sync;
    reg [1:0] copi_sync;
    reg [1:0] ncs_sync;

    // i know that sclk posedge is useful idk about the others
    reg sclk_last;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_last <= 1'b0;
        else
            sclk_last <= sclk_sync[1];
    end

    wire sclk_posedge = sclk_sync[1] & ~sclk_last;

    // we only hold 15 at a time
    reg [14:0] received;
    reg [3:0]  bit_counter; // only need to count 16 bits

    // synchronisation and edge history
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 2'b00;
            copi_sync <= 2'b00;
            ncs_sync  <= 2'b00; 
        end 
        else begin
            sclk_sync <= {sclk_sync[0], new_sclk};
            copi_sync <= {copi_sync[0], new_copi};
            ncs_sync  <= {ncs_sync[0], new_ncs};
        end
    end

    // collect spi bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            received    <= 15'b0;
            bit_counter <= 4'b0;
        end
        else if (ncs_sync[1]) begin // means no transaction (activity)
            bit_counter <= 4'b0;
        end
        else if (sclk_posedge) begin
            received    <= {received[13:0], copi_sync[1]};
            bit_counter <= bit_counter + 1'b1;
        end
    end

    // receive SPI transaction and update registers.
    wire [15:0] input_signal = {received, copi_sync[1]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0  <= 8'h00;
            en_reg_out_15_8 <= 8'h00;
            en_reg_pwm_7_0  <= 8'h00;
            en_reg_pwm_15_8 <= 8'h00;
            pwm_duty_cycle  <= 8'h00;
        end    // clock increased, chip is active, currently 16 bits
        else if (sclk_posedge && !ncs_sync[1] && bit_counter == 4'hF) begin
            if (input_signal[15]) begin
                case (input_signal[14:8])
                    7'h00: en_reg_out_7_0  <= input_signal[7:0]; // Enable outputs on `uo_out[7:0]`
                    7'h01: en_reg_out_15_8 <= input_signal[7:0]; // Enable outputs on `uio_out[7:0]`
                    7'h02: en_reg_pwm_7_0  <= input_signal[7:0]; // Enable PWM for `uo_out[7:0]`
                    7'h03: en_reg_pwm_15_8 <= input_signal[7:0]; // Enable PWM for `uio_out[7:0]`
                    7'h04: pwm_duty_cycle  <= input_signal[7:0]; // PWM Duty Cycle ( `0x00`=0%, `0xFF`=100%)
                    default: ; // invalid address
                endcase
            end
        end
    end

endmodule