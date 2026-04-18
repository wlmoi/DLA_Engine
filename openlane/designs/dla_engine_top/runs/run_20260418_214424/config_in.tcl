set ::env(DESIGN_NAME) "dla_engine_top"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.sv]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) 20.0

set ::env(FP_CORE_UTIL) 45
set ::env(FP_ASPECT_RATIO) 1.0
set ::env(PL_TARGET_DENSITY) 0.45
set ::env(SYNTH_STRATEGY) "AREA 2"

set ::env(DESIGN_IS_CORE) 1
set ::env(QUIT_ON_MAGIC_DRC) 1
set ::env(QUIT_ON_LVS_ERROR) 1
