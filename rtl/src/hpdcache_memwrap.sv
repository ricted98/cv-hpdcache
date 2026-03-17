// Copyright 2026 ETH Zurich, University of Bologna
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//      https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

module hpdcache_memwrap
import hpdcache_pkg::*;
#(
    parameter  hpdcache_cfg_t         HPDcacheCfg = '0,
    parameter type                    hpdcache_way_vector_t = logic,
    parameter type                    hpdcache_dir_addr_t = logic,
    parameter type                    hpdcache_dir_entry_t = logic,
    parameter type                    hpdcache_data_addr_t = logic,
    parameter type                    hpdcache_data_enable_t = logic,
    parameter type                    hpdcache_data_be_entry_t = logic,
    parameter type                    hpdcache_data_entry_t = logic,
    parameter type                    hpdcache_data_row_enable_t = logic,
    parameter type                    hpdcache_data_ram_word_sel_t = logic
) (
    input  logic clk_i,
    input  logic rst_ni,

    // Directory interface
    input  hpdcache_way_vector_t                                 dir_cs_i,
    input  hpdcache_way_vector_t                                 dir_we_i,
    input  hpdcache_dir_addr_t                                   dir_addr_i,
    input  hpdcache_dir_entry_t [HPDcacheCfg.u.ways-1:0]         dir_wentry_i,
    output hpdcache_dir_entry_t [HPDcacheCfg.u.ways-1:0]         dir_rentry_o,
    output hpdcache_way_vector_t                                 dir_err_cor_o,
    output hpdcache_way_vector_t                                 dir_err_unc_o,
    output hpdcache_way_vector_t                                 dir_err_valid_o,
    output hpdcache_way_vector_t                                 dir_err_dirty_o,

    // Data interface
    input  hpdcache_data_addr_t                                  data_addr_i,
    input  hpdcache_data_enable_t                                data_cs_i,
    input  hpdcache_data_enable_t                                data_we_i,
    input  hpdcache_data_be_entry_t                              data_wbyteenable_i,
    input  hpdcache_data_entry_t                                 data_wentry_i,
    output hpdcache_data_entry_t                                 data_rentry_o,
    output hpdcache_data_ram_word_sel_t                          data_err_cor_o,
    output hpdcache_data_ram_word_sel_t                          data_err_unc_o
);

    genvar x, y, dir_w;

    //  Directory
    //
    for (dir_w = 0; dir_w < int'(HPDcacheCfg.u.ways); dir_w++) begin : gen_dir_sram
        hpdcache_sram #(
            .ADDR_SIZE (HPDcacheCfg.dirRamAddrWidth),
            .DATA_SIZE (HPDcacheCfg.dirRamWidth),
            .NDATA     (1),
            .ECC_EN    (HPDcacheCfg.u.eccEn)
        ) dir_sram(
            .clk           (clk_i),
            .rst_n         (rst_ni),
            .cs            (dir_cs_i[dir_w]),
            .we            (dir_we_i[dir_w]),
            .addr          (dir_addr_i),
            .wdata         (dir_wentry_i[dir_w]),
            .rdata         (dir_rentry_o[dir_w]),
            .err_inj_i     (1'b0),
            .err_inj_msk_i ('0),
            .err_cor_o     (dir_err_cor_o[dir_w]),
            .err_unc_o     (dir_err_unc_o[dir_w])
        );
        assign dir_err_valid_o[dir_w] = dir_rentry_o[dir_w].valid;
        assign dir_err_dirty_o[dir_w] = dir_rentry_o[dir_w].dirty;
    end

    //  Data
    //
    for (y = 0; y < int'(HPDcacheCfg.dataRamYCuts); y++) begin : gen_data_sram_row
        for (x = 0; x < int'(HPDcacheCfg.dataRamXCuts); x++) begin : gen_data_sram_col
            hpdcache_sram_wbyteenable #(
                .ADDR_SIZE (HPDcacheCfg.dataRamAddrWidth),
                .DATA_SIZE (HPDcacheCfg.u.wordWidth),
                .NDATA     (HPDcacheCfg.u.dataWaysPerRamWord),
                .ECC_EN    (HPDcacheCfg.u.eccEn)
            ) data_sram(
                .clk           (clk_i),
                .rst_n         (rst_ni),
                .cs            (data_cs_i[y][x]),
                .we            (data_we_i[y][x]),
                .addr          (data_addr_i[y][x]),
                .wdata         (data_wentry_i[y][x]),
                .wbyteenable   (data_wbyteenable_i[y][x]),
                .rdata         (data_rentry_o[y][x]),
                .err_inj_i     (1'b0),
                .err_inj_msk_i ('0),
                .err_cor_o     (data_err_cor_o[y][x]),
                .err_unc_o     (data_err_unc_o[y][x])
            );
        end
    end
endmodule
