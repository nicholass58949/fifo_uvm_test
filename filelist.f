# Async FIFO Verification File List
# 编译顺序很重要
# 编译命令示例:
#   VCS:     vcs -sverilog -ntb_opts uvm-1.2 +incdir+tb -f filelist.f
#   Questa:  vlog -sv +incdir+$UVM_HOME/src +incdir+tb -f filelist.f
#   Xcelium: xrun -sv -uvm +incdir+tb -f filelist.f

# DUT files
rtl/async_fifo.sv

# Interface
tb/common/fifo_interface.sv

# Assertions
tb/common/fifo_assertions.sv

# UVM Package (包含所有验证组件)
# 使用 +incdir+tb 指定include路径
tb/fifo_pkg.sv

# Testbench Top
tb/tb_top.sv
