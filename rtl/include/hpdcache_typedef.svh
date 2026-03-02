/*
 *  Copyright 2023,2024 Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *  Copyright 2025 Univ. Grenoble Alpes, Inria, TIMA Laboratory
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 */
/*
 *  Authors       : Cesar Fuguet
 *  Creation Date : February, 2023
 *  Description   : HPDcache Types' Definition
 *  History       :
 */
`ifndef __HPDCACHE_TYPEDEF_SVH__
`define __HPDCACHE_TYPEDEF_SVH__

`define HPDCACHE_DECL_MEM_REQ_T(__addr_t, __id_t) \
    struct packed { \
        __addr_t                              mem_req_addr; \
        hpdcache_pkg::hpdcache_mem_len_t      mem_req_len; \
        hpdcache_pkg::hpdcache_mem_size_t     mem_req_size; \
        __id_t                                mem_req_id; \
        hpdcache_pkg::hpdcache_mem_command_e  mem_req_command; \
        hpdcache_pkg::hpdcache_mem_atomic_e   mem_req_atomic; \
        logic                                 mem_req_cacheable; \
    }

`define HPDCACHE_DECL_MEM_RESP_R_T(__id_t, __data_t) \
    struct packed { \
        hpdcache_pkg::hpdcache_mem_error_e    mem_resp_r_error; \
        __id_t                                mem_resp_r_id; \
        __data_t                              mem_resp_r_data; \
        logic                                 mem_resp_r_last; \
    }

`define HPDCACHE_DECL_MEM_REQ_W_T(__data_t, __be_t) \
    struct packed { \
        __data_t                              mem_req_w_data; \
        __be_t                                mem_req_w_be; \
        logic                                 mem_req_w_last; \
    }

`define HPDCACHE_DECL_MEM_RESP_W_T(__id_t) \
    struct packed { \
        logic                                 mem_resp_w_is_atomic; \
        hpdcache_pkg::hpdcache_mem_error_e    mem_resp_w_error; \
        __id_t                                mem_resp_w_id; \
    }

`define HPDCACHE_TYPEDEF_MEM_ATTR_T(__addr_t, __id_t, __data_t, __be_t, __params) \
    typedef logic [  __params.u.memAddrWidth-1:0] __addr_t; \
    typedef logic [    __params.u.memIdWidth-1:0] __id_t; \
    typedef logic [  __params.u.memDataWidth-1:0] __data_t; \
    typedef logic [__params.u.memDataWidth/8-1:0] __be_t

`define HPDCACHE_TYPEDEF_MEM_REQ_T(__name__, __addr_t, __id_t) \
    typedef `HPDCACHE_DECL_MEM_REQ_T(__addr_t, __id_t) __name__

`define HPDCACHE_TYPEDEF_MEM_RESP_R_T(__name__, __id_t, __data_t) \
    typedef `HPDCACHE_DECL_MEM_RESP_R_T(__id_t, __data_t) __name__

`define HPDCACHE_TYPEDEF_MEM_REQ_W_T(__name__, __data_t, __be_t) \
    typedef `HPDCACHE_DECL_MEM_REQ_W_T(__data_t, __be_t) __name__

`define HPDCACHE_TYPEDEF_MEM_RESP_W_T(__name__, __id_t) \
    typedef `HPDCACHE_DECL_MEM_RESP_W_T(__id_t) __name__

`define HPDCACHE_DECL_REQ_T(__offset_t, __data_t, __be_t, __sid_t, __tid_t, __tag_t) \
    struct packed { \
        __offset_t                        addr_offset; \
        __data_t                          wdata; \
        hpdcache_pkg::hpdcache_req_op_t   op; \
        __be_t                            be; \
        hpdcache_pkg::hpdcache_req_size_t size; \
        __sid_t                           sid; \
        __tid_t                           tid; \
        logic                             need_rsp; \
        logic                             phys_indexed; \
        __tag_t                           addr_tag; \
        hpdcache_pkg::hpdcache_pma_t      pma; \
    }

`define HPDCACHE_TYPEDEF_REQ_ATTR_T(__offset_t, __word_t, __word_be_t, __data_t, __be_t, __sid_t, __tid_t, __tag_t, __params) \
    typedef logic       [         __params.tagWidth-1:0] __tag_t; \
    typedef logic       [      __params.u.wordWidth-1:0] __word_t; \
    typedef logic       [    __params.u.wordWidth/8-1:0] __word_be_t; \
    typedef logic       [   __params.reqOffsetWidth-1:0] __offset_t; \
    typedef __word_t    [       __params.u.reqWords-1:0] __data_t; \
    typedef __word_be_t [       __params.u.reqWords-1:0] __be_t; \
    typedef logic       [  __params.u.reqSrcIdWidth-1:0] __sid_t; \
    typedef logic       [__params.u.reqTransIdWidth-1:0] __tid_t

`define HPDCACHE_TYPEDEF_REQ_T(__name__, __offset_t, __data_t, __be_t, __sid_t, __tid_t, __tag_t) \
    typedef `HPDCACHE_DECL_REQ_T(__offset_t, __data_t, __be_t, __sid_t, __tid_t, __tag_t) __name__

`define HPDCACHE_DECL_RSP_T(__data_t, __sid_t, __tid_t) \
    struct packed { \
        __data_t rdata; \
        __sid_t  sid; \
        __tid_t  tid; \
        logic    error; \
        logic    aborted; \
    }

`define HPDCACHE_TYPEDEF_RSP_T(__name__, __data_t, __sid_t, __tid_t) \
    typedef `HPDCACHE_DECL_RSP_T(__data_t, __sid_t, __tid_t) __name__

`define HPDCACHE_DECL_EXT_SRAM_REQ_T(__params) \
    struct packed { \
        logic unsigned [                                                       __params.u.ways-1:0] dir_cs; \
        logic unsigned [                                                       __params.u.ways-1:0] dir_we; \
        logic          [                                              __params.dirRamAddrWidth-1:0] dir_addr; \
        logic          [                               __params.u.ways-1:0][__params.dirEntryWidth-1:0] dir_wentry; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.dataRamAddrWidth-1:0] data_addr; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] data_cs; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] data_we; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.u.dataWaysPerRamWord-1:0][__params.u.wordWidth/8-1:0] data_wbyteenable; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.u.dataWaysPerRamWord-1:0][__params.u.wordWidth-1:0]   data_wentry; \
    }
`define HPDCACHE_TYPEDEF_EXT_SRAM_REQ_T(__name__, __params) \
    typedef `HPDCACHE_DECL_EXT_SRAM_REQ_T(__params) __name__


`define HPDCACHE_DECL_EXT_SRAM_RESP_T(__params) \
    struct packed { \
        logic          [                               __params.u.ways-1:0][__params.dirEntryWidth-1:0] dir_rentry; \
        logic unsigned [                                                       __params.u.ways-1:0] dir_err_cor; \
        logic unsigned [                                                       __params.u.ways-1:0] dir_err_unc; \
        logic unsigned [                                                       __params.u.ways-1:0] dir_err_valid; \
        logic unsigned [                                                       __params.u.ways-1:0] dir_err_dirty; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.u.dataWaysPerRamWord-1:0][__params.u.wordWidth-1:0] data_rentry; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.u.dataWaysPerRamWord-1:0] data_err_cor; \
        logic          [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0][__params.u.dataWaysPerRamWord-1:0] data_err_unc; \
    }

`define HPDCACHE_TYPEDEF_EXT_SRAM_RESP_T(__name__, __params) \
    typedef `HPDCACHE_DECL_EXT_SRAM_RESP_T(__params) __name__

`define HPDCACHE_TYPEDEF_RAM_TYPES_T(__name__, __params) \
    typedef logic [                       __params.dirRamAddrWidth-1:0] __name__``_dir_addr_t; \
    typedef logic [                      __params.dataRamAddrWidth-1:0] __name__``_data_ram_addr_t; \
    typedef logic [__params.u.dataWaysPerRamWord-1:0][__params.u.wordWidth-1:0]   __name__``_data_ram_data_t; \
    typedef logic [__params.u.dataWaysPerRamWord-1:0][__params.u.wordWidth/8-1:0] __name__``_data_ram_be_t; \
    \
    typedef logic [                          __params.dataRamYCuts-1:0] __name__``_data_ram_row_idx_t; \
    typedef logic [$clog2(__params.u.dataWaysPerRamWord)-1:0]           __name__``_data_ram_way_idx_t; \
    typedef logic [                          __params.dataRamXCuts-1:0] __name__``_data_row_enable_t; \
    typedef __name__``_data_row_enable_t [    __params.dataRamYCuts-1:0] __name__``_data_enable_t; \
    typedef logic [                  __params.u.dataWaysPerRamWord-1:0] __name__``_data_ram_way_sel_t; \
    \
    typedef __name__``_data_ram_data_t   [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] __name__``_data_entry_t; \
    typedef __name__``_data_ram_be_t     [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] __name__``_data_be_entry_t; \
    typedef __name__``_data_ram_addr_t   [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] __name__``_data_addr_t; \
    typedef __name__``_data_ram_way_sel_t [__params.dataRamYCuts-1:0][__params.dataRamXCuts-1:0] __name__``_data_ram_word_sel_t;

`endif //  __HPDCACHE_TYPEDEF_SVH__
