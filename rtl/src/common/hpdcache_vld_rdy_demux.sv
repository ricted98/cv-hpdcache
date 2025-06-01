// Copyright (c) 2025 ETH Zurich, University of Bologna
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.1 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.1. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

//
// Authors       : Riccardo Tedeschi
// Creation Date : May, 2025
// Description   : Valid/Ready handshake demux
// History       :
//

module hpdcache_vld_rdy_demux
    //  Parameters
#(
    //  Number of outputs
    parameter  int unsigned NOUTPUT     = 0,
    //  Selector signal is one-hot encoded
    parameter  bit          ONE_HOT_SEL = 0,
    //  Compute the width of the selection signal
    localparam int unsigned NOUTPUT_LOG2 = NOUTPUT > 1 ? $clog2(NOUTPUT) : 1,
    localparam int unsigned SEL_WIDTH    = ONE_HOT_SEL ? NOUTPUT : NOUTPUT_LOG2,

    localparam type sel_t  = logic [SEL_WIDTH-1:0]
)
    //  Ports
(
    input  logic               vld_i,
    output logic               rdy_o,

    input  sel_t               sel_i,

    output logic [NOUTPUT-1:0] vld_o,
    input  logic [NOUTPUT-1:0] rdy_i
);

    if (ONE_HOT_SEL) begin : gen_onehot_sel
        always_comb begin
            vld_o = '0;
            rdy_o = 1'b0;
            for (int unsigned i = 0; i < NOUTPUT; i++) begin
                if (sel_i[i]) begin
                    vld_o[i] = vld_i;
                    rdy_o    = rdy_i[i];
                end
            end
        end
    end else begin : gen_bin_sel
        always_comb begin : demux_comb
            vld_o = '0;
            vld_o[sel_i] = vld_i;
            rdy_o = rdy_i[sel_i];
        end
    end

endmodule
