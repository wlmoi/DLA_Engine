set env CARRY_SELECT_ADDER_MAP pdk/gf180mcuA/libs.tech/openlane/gf180mcu_fd_sc_mcu7t5v0/csa_map.v
set env CLOCK_PERIOD 20.0
set env DESIGN_NAME dla_engine_top
set env FULL_ADDER_MAP pdk/gf180mcuA/libs.tech/openlane/gf180mcu_fd_sc_mcu7t5v0/fa_map.v
set env LIB_SYNTH ./tmp/synthesis/trimmed.lib
set env LIB_SYNTH_COMPLETE pdk/gf180mcuA/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib/gf180mcu_fd_sc_mcu7t5v0__tt_025C_5v00.lib
set env LIB_SYNTH_COMPLETE_NO_PG ./tmp/synthesis/1-gf180mcu_fd_sc_mcu7t5v0__tt_025C_5v00.no_pg.lib
set env LIB_SYNTH_NO_PG ./tmp/synthesis/1-trimmed.no_pg.lib
set env MAX_FANOUT_CONSTRAINT 10
set env MAX_TRANSITION_CONSTRAINT 3
set env OUTPUT_CAP_LOAD 72.91
set env PACKAGED_SCRIPT_0 nix/store/xpc7xd67rslanlqh566s6jph53bn830w-openlane1-1.1.1/bin/scripts/yosys/synth.tcl
set env PACKAGED_SCRIPT_1 ./tmp/synthesis/synthesis.sdc
set env RIPPLE_CARRY_ADDER_MAP pdk/gf180mcuA/libs.tech/openlane/gf180mcu_fd_sc_mcu7t5v0/rca_map.v
set env SAVE_NETLIST ./results/synthesis/dla_engine_top.v
set env SYNTH_ABC_LEGACY_REFACTOR 0
set env SYNTH_ABC_LEGACY_REWRITE 0
set env SYNTH_ADDER_TYPE YOSYS
set env SYNTH_BUFFERING 1
set env SYNTH_BUFFER_DIRECT_WIRES 1
set env SYNTH_DRIVING_CELL gf180mcu_fd_sc_mcu7t5v0__inv_1
set env SYNTH_EXTRA_MAPPING_FILE 
set env SYNTH_LATCH_MAP pdk/gf180mcuA/libs.tech/openlane/gf180mcu_fd_sc_mcu7t5v0/latch_map.v
set env SYNTH_MIN_BUF_PORT gf180mcu_fd_sc_mcu7t5v0__buf_1 I Z
set env SYNTH_NO_FLAT 0
set env SYNTH_SHARE_RESOURCES 1
set env SYNTH_SIZING 0
set env SYNTH_SPLITNETS 1
set env SYNTH_STRATEGY AREA 2
set env SYNTH_TIEHI_PORT gf180mcu_fd_sc_mcu7t5v0__tieh Z
set env SYNTH_TIELO_PORT gf180mcu_fd_sc_mcu7t5v0__tiel ZN
set env TRISTATE_BUFFER_MAP pdk/gf180mcuA/libs.tech/openlane/gf180mcu_fd_sc_mcu7t5v0/tribuff_map.v
set env VERILOG_FILES project/openlane/designs/dla_engine_top/src/dla_a_buffer_bank.sv project/openlane/designs/dla_engine_top/src/dla_b_buffer_bank.sv project/openlane/designs/dla_engine_top/src/dla_controller.sv project/openlane/designs/dla_engine_top/src/dla_engine_top.sv project/openlane/designs/dla_engine_top/src/dla_pe.sv project/openlane/designs/dla_engine_top/src/dla_pe_array.sv
set env synth_report_prefix ./reports/synthesis/1-synthesis
set env synthesis_results ./results/synthesis
set env synthesis_tmpfiles ./tmp/synthesis