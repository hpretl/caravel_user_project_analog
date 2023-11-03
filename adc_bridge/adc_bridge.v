// Copyright 2023 Harald Pretl, IIC, JKU
//
// This digital module serves as a bridge between the (few) digital IOs and the
// ADC digital IOs. A shift register is realized for the configuration bits, and
// also the conversion result of the ADC.

`default_nettype none

module adc_bridge (
    // chip inputs
    input wire              clk,        // clk for shift regs
    input wire              rst_n,      // async. reset for regs
    input wire              dat_i,      // serial in (ADC config, LSB first)
    input wire              load,       // load strobe for shift regs
    // interface to ADC
    input wire [15:0]       adc_res,    // ADC result input
    output wire [15:0]      adc_cfg1,   // ADC config1 output
    output wire [15:0]      adc_cfg2,   // ADC config2 output
    // chip outputs
    output wire             dat_o,      // serial out (ADC result, LSB first)
    output wire             tie1,       // logic 1 aux. output
    output wire             tie0        // logic 2 aux. output
    );

    // define local register used for shifting and storing
    reg [31:0] adc_cfg_store_r;
    reg [31:0] adc_cfg_load_r;
    reg [19:0] adc_res_r;

    // outputs
    assign dat_o = adc_res_r[0];
    assign adc_cfg1 = adc_cfg_store_r[15:0];
    assign adc_cfg2 = adc_cfg_store_r[31:16];
    assign tie1=1'b1;
    assign tie0=1'b0;

    // on clk, shift config in, and result out (LSB first)
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            // reset
            adc_cfg_store_r <= 32'd0;
            adc_cfg_load_r <= 32'd0;
            adc_res_r <= 20'd0;
        end else begin
            if (clk == 1'b1) begin
                if (load == 1'b0) begin
                    // shift
                    adc_res_r <= {1'b0,adc_res_r[19:1]};
                    adc_cfg_load_r <= {dat_i,adc_cfg_load_r[31:1]};
                end else begin
                    // store
                    // add a bit of framing 10xxxx01 for easier detection of correct data
                    adc_res_r <= {2'b10,adc_res,2'b01};
                    adc_cfg_store_r <= adc_cfg_load_r;
                end
            end
        end
    end

endmodule // adc_bridge