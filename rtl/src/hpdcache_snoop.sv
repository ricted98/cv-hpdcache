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

/*
 *  Authors       : Riccardo Tedeschi
 *  Creation Date : June, 2025
 *  Description   : HPDcache Snoop Handler
 *  History       :
 */

module hpdcache_snoop
import hpdcache_pkg::*;
//  Parameters
//  {{{
#(
    parameter hpdcache_cfg_t HPDcacheCfg = '0,
    parameter type hpdcache_rsp_t = logic,
    parameter type hpdcache_req_tid_t = logic,
    parameter type hpdcache_req_sid_t = logic,
    parameter type hpdcache_tag_t = logic,
    parameter type hpdcache_set_t = logic,
    parameter type hpdcache_way_vector_t = logic,
    parameter type hpdcache_word_t = logic,
    parameter type hpdcache_access_data_t = logic,
    parameter type hpdcache_mem_req_w_t = logic,
    parameter type hpdcache_mem_data_t = logic

)
//  }}}

//  Ports
//  {{{
(
    input  logic                  clk_i,
    input  logic                  rst_ni,

    //  Cache-side request interface
    //  {{{
    input  logic                  req_valid_i,
    output logic                  req_ready_o,
    input  hpdcache_snoop_op_t    req_op_i,
    input  hpdcache_req_tid_t     req_tid_i,
    input  hpdcache_req_sid_t     req_sid_i,
    input  hpdcache_set_t         req_set_i,
    input  hpdcache_tag_t         req_tag_i,
    input  hpdcache_way_vector_t  req_way_i,
    input  logic                  req_dir_valid_i,
    input  logic                  req_dir_wback_i,
    input  logic                  req_dir_dirty_i,
    input  logic                  req_dir_shared_i,
    input  logic                  req_dir_fetch_i,
    //  }}}

    //  CACHE DIR interface
    //  {{{
    output logic                  dir_updt_o,
    output hpdcache_set_t         dir_updt_set_o,
    output hpdcache_way_vector_t  dir_updt_way_o,
    output logic                  dir_updt_valid_o,
    output logic                  dir_updt_wback_o,
    output logic                  dir_updt_dirty_o,
    output logic                  dir_updt_shared_o,
    output logic                  dir_updt_fetch_o,
    output hpdcache_tag_t         dir_updt_tag_o,
    // }}}

    //  CACHE DATA interface
    //  {{{
    output logic                  data_read_o,
    output hpdcache_set_t         data_read_set_o,
    output hpdcache_word_t        data_read_word_o,
    output hpdcache_way_vector_t  data_read_way_o,
    input  hpdcache_access_data_t data_read_data_i,
    //      }}}

    //  SNOOP interface
    //  {{{
    input  logic                  snoop_rsp_ready_i,
    output logic                  snoop_rsp_valid_o,
    output hpdcache_coherence_t   snoop_meta_o,
    output hpdcache_rsp_t         snoop_rsp_o,
    input  logic                  snoop_data_ready_i,
    output logic                  snoop_data_valid_o,
    output hpdcache_mem_req_w_t   snoop_data_o
    //  }}}
);

    typedef enum {
        SNOOP_IDLE,
        SNOOP_DATA_READ_FIRST,
        SNOOP_DATA_READ_NEXT,
        SNOOP_DIR_UPDT
    } snoop_fsm_e;

    typedef struct packed {
        hpdcache_coherence_t meta;
        hpdcache_req_tid_t tid;
        hpdcache_req_sid_t sid;
    } snoop_rsp_t;

    snoop_fsm_e snoop_fsm_q, snoop_fsm_d;

    snoop_rsp_t resp_wdata;
    logic resp_w;
    logic resp_wok;
    snoop_rsp_t resp_rdata;
    logic resp_r;
    logic resp_rok;

    logic                  resp_data_w;
    logic                  resp_data_wok;
    hpdcache_access_data_t resp_data_wdata;
    logic                  resp_data_wlast;
    logic                  resp_data_r;
    logic                  resp_data_rok;
    hpdcache_mem_data_t    resp_data_rdata;
    logic                  resp_data_rlast;

    hpdcache_word_t req_word_q, req_word_d;

    hpdcache_snoop_op_t    req_op_q;
    hpdcache_set_t         req_set_q;
    hpdcache_tag_t         req_tag_q;
    hpdcache_way_vector_t  req_way_q;
    logic                  req_dir_wback_q;
    logic                  req_dir_dirty_q;
    logic                  req_dir_shared_q;
    logic                  req_dir_fetch_q;

    logic data_eol;

    assign req_ready_o = &{
        snoop_fsm_q == SNOOP_IDLE,
        resp_wok,
        resp_data_wok
    };

    assign data_eol = (req_word_q == 0);

    always_comb begin

        snoop_fsm_d = snoop_fsm_q;
        req_word_d = req_word_q;

        resp_wdata = '0;
        resp_w = 1'b0;

        resp_data_w = 1'b0;
        resp_data_wlast = 1'b0;

        data_read_o = 1'b0;
        dir_updt_o  = 1'b0;

        resp_wdata.sid = req_sid_i;
        resp_wdata.tid = req_tid_i;

        dir_updt_valid_o  = 1'b0;
        dir_updt_wback_o  = 1'b0;
        dir_updt_dirty_o  = 1'b0;
        dir_updt_shared_o = 1'b0;
        dir_updt_fetch_o  = 1'b0;

        case (snoop_fsm_q)
            SNOOP_IDLE: begin
                if (req_valid_i && req_ready_o) begin
                    resp_w = 1'b1;
                    if (!req_dir_valid_i) begin
                        resp_wdata.meta.was_unique    = 1'b0;
                        resp_wdata.meta.is_shared     = 1'b0;
                        resp_wdata.meta.pass_dirty    = 1'b0;
                        resp_wdata.meta.left_dirty    = 1'b0;
                        resp_wdata.meta.data_transfer = 1'b0;
                    end else begin
                        unique case (1'b1)
                            req_op_i.is_read_clean,
                            req_op_i.is_read_not_shared_dirty,
                            req_op_i.is_read_once,
                            req_op_i.is_read_shared: begin
                                resp_wdata.meta.was_unique    = !req_dir_shared_i;
                                resp_wdata.meta.is_shared     = 1'b1;
                                resp_wdata.meta.pass_dirty    = 1'b0;
                                resp_wdata.meta.left_dirty    = req_dir_dirty_i;
                                resp_wdata.meta.data_transfer = 1'b1;

                                snoop_fsm_d = SNOOP_DATA_READ_FIRST;
                            end

                            req_op_i.is_read_unique: begin
                                resp_wdata.meta.was_unique    = !req_dir_shared_i;
                                resp_wdata.meta.is_shared     = 1'b0;
                                resp_wdata.meta.pass_dirty    = req_dir_dirty_i;
                                resp_wdata.meta.left_dirty    = 1'b0;
                                resp_wdata.meta.data_transfer = 1'b1;

                                snoop_fsm_d = SNOOP_DATA_READ_FIRST;
                            end

                            req_op_i.is_clean_invalid: begin
                                resp_wdata.meta.was_unique    = !req_dir_shared_i;
                                resp_wdata.meta.is_shared     = 1'b0;
                                resp_wdata.meta.pass_dirty    = req_dir_dirty_i;
                                resp_wdata.meta.left_dirty    = 1'b0;
                                resp_wdata.meta.data_transfer = req_dir_dirty_i;
                                if (req_dir_dirty_i) begin
                                    snoop_fsm_d = SNOOP_DATA_READ_FIRST;
                                end else begin
                                    snoop_fsm_d = SNOOP_DIR_UPDT;
                                end
                            end

                            req_op_i.is_clean_shared: begin
                                resp_wdata.meta.was_unique    = !req_dir_shared_i;
                                resp_wdata.meta.is_shared     = 1'b1;
                                resp_wdata.meta.pass_dirty    = req_dir_dirty_i;
                                resp_wdata.meta.left_dirty    = 1'b0;
                                resp_wdata.meta.data_transfer = req_dir_dirty_i;
                                if (req_dir_dirty_i) begin
                                    snoop_fsm_d = SNOOP_DATA_READ_FIRST;
                                end else begin
                                    snoop_fsm_d = SNOOP_DIR_UPDT;
                                end
                            end

                            req_op_i.is_make_invalid: begin
                                resp_wdata.meta.was_unique    = !req_dir_shared_i;
                                resp_wdata.meta.is_shared     = 1'b0;
                                resp_wdata.meta.pass_dirty    = 1'b0;
                                resp_wdata.meta.left_dirty    = 1'b0;
                                resp_wdata.meta.data_transfer = 1'b0;
                            end

                            default: begin
                                resp_wdata.meta.was_unique    = 1'b0;
                                resp_wdata.meta.is_shared     = 1'b0;
                                resp_wdata.meta.pass_dirty    = 1'b0;
                                resp_wdata.meta.left_dirty    = 1'b0;
                                resp_wdata.meta.data_transfer = 1'b0;
                            end
                        endcase
                    end
                end
            end

            SNOOP_DATA_READ_FIRST: begin
                resp_data_w = 1'b0;
                resp_data_wlast = 1'b0;

                if (resp_data_wok) begin
                    data_read_o = 1'b1;
                    req_word_d = req_word_q + hpdcache_word_t'(HPDcacheCfg.u.accessWords);
                    snoop_fsm_d = SNOOP_DATA_READ_NEXT;
                end

            end

            SNOOP_DATA_READ_NEXT: begin
                resp_data_w = 1'b1;
                resp_data_wlast = data_eol;

                if (resp_data_wok) begin
                    data_read_o = !data_eol;
                    if (data_eol) begin
                        snoop_fsm_d = req_op_q.is_read_once ? SNOOP_IDLE : SNOOP_DIR_UPDT;
                    end else begin
                        req_word_d = req_word_q + hpdcache_word_t'(HPDcacheCfg.u.accessWords);
                    end
                end
            end

            SNOOP_DIR_UPDT: begin
                snoop_fsm_d = SNOOP_IDLE;
                dir_updt_o = 1'b1;

                unique case (1'b1)
                    req_op_q.is_read_clean,
                    req_op_q.is_read_not_shared_dirty,
                    req_op_q.is_read_shared: begin
                        dir_updt_valid_o  = 1'b1;
                        dir_updt_wback_o  = req_dir_wback_q;
                        dir_updt_dirty_o  = req_dir_dirty_q;
                        dir_updt_shared_o = 1'b1;
                        dir_updt_fetch_o  = req_dir_fetch_q;
                    end

                    req_op_q.is_read_unique,
                    req_op_q.is_clean_invalid,
                    req_op_q.is_make_invalid: begin
                        dir_updt_valid_o  = 1'b0;
                        dir_updt_wback_o  = 1'b0;
                        dir_updt_dirty_o  = 1'b0;
                        dir_updt_shared_o = 1'b0;
                        dir_updt_fetch_o  = 1'b0;
                    end

                    req_op_q.is_clean_shared: begin
                        dir_updt_valid_o  = 1'b1;
                        dir_updt_wback_o  = req_dir_wback_q;
                        dir_updt_dirty_o  = 1'b0;
                        dir_updt_shared_o = req_dir_shared_q;
                        dir_updt_fetch_o  = req_dir_fetch_q;
                    end

                    default: begin
                        resp_wdata.meta.was_unique    = 1'b0;
                        resp_wdata.meta.is_shared     = 1'b0;
                        resp_wdata.meta.pass_dirty    = 1'b0;
                        resp_wdata.meta.left_dirty    = 1'b0;
                        resp_wdata.meta.data_transfer = 1'b0;
                    end
                endcase
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            snoop_fsm_q <= SNOOP_IDLE;
            req_word_q <= '0;
        end else begin
            snoop_fsm_q <= snoop_fsm_d;
            req_word_q <= req_word_d;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            req_op_q <= '0;
            req_dir_wback_q <= 1'b0;
            req_dir_dirty_q <= 1'b0;
            req_dir_shared_q <= 1'b0;
            req_dir_fetch_q <= 1'b0;
            req_set_q <= '0;
            req_way_q <= '0;
            req_tag_q <= '0;
        end else if (req_valid_i && req_ready_o) begin
            req_dir_wback_q <= req_dir_wback_i;
            req_dir_dirty_q <= req_dir_dirty_i;
            req_dir_shared_q <= req_dir_shared_i;
            req_dir_fetch_q <= req_dir_fetch_i;
            req_set_q <= req_set_i;
            req_way_q <= req_way_i;
            req_tag_q <= req_tag_i;
        end
    end

    assign data_read_set_o  = req_set_q;
    assign data_read_way_o  = req_way_q;
    assign data_read_word_o = req_word_q;

    assign dir_updt_set_o = req_set_q;
    assign dir_updt_way_o = req_way_q;
    assign dir_updt_tag_o = req_tag_q;

    //  Sync metadata response with interface signals
    //
    hpdcache_sync_buffer #(
        .FEEDTHROUGH (1'b0),
        .data_t      (snoop_rsp_t)
    ) snoop_resp_buffer_i (
        .clk_i,
        .rst_ni,
        .w_i         (resp_w),
        .wok_o       (resp_wok),
        .wdata_i     (resp_wdata),
        .r_i         (resp_r),
        .rok_o       (resp_rok),
        .rdata_o     (resp_rdata)
    );

    //  Resize data width from the cache controller to the NoC data width
    //
    hpdcache_data_resize #(
        .WR_WIDTH       (HPDcacheCfg.accessWidth),
        .RD_WIDTH       (HPDcacheCfg.u.memDataWidth),
        .DEPTH          (HPDcacheCfg.u.snoopFifoDepth)
    ) snoop_data_resizer_i(
        .clk_i,
        .rst_ni,
        .w_i            (resp_data_w),
        .wok_o          (resp_data_wok),
        .wdata_i        (resp_data_wdata),
        .wlast_i        (resp_data_wlast),
        .r_i            (resp_data_r),
        .rok_o          (resp_data_rok),
        .rdata_o        (resp_data_rdata),
        .rlast_o        (resp_data_rlast)
    );

    //  Inputs
    assign resp_data_wdata = data_read_data_i;

    //  Outputs
    assign resp_r             = snoop_rsp_ready_i;
    assign snoop_rsp_valid_o  = resp_rok;
    assign snoop_meta_o       = resp_rdata.meta;
    assign snoop_rsp_o        = '{
        tid: resp_rdata.tid,
        sid: resp_rdata.sid,
        default: '0
    };
    assign resp_data_r        = snoop_data_ready_i;
    assign snoop_data_valid_o = resp_data_rok;
    assign snoop_data_o       = '{
        mem_req_w_data: resp_data_rdata,
        mem_req_w_be: '1,
        mem_req_w_last: resp_data_rlast
    };

endmodule
