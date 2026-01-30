import os
import sys
import subprocess
import shutil

# 仿真器选择: 'vcs', 'questa', 'xcelium'
SIMULATOR = 'vcs'  # 可修改为 'questa' 或 'xcelium'

# 文件列表
FILELIST = 'filelist.f'
TOP_MODULE = 'tb_top'
SIMV = 'simv'  # VCS 默认输出
WORK_DIR = 'work'  # Questa 默认工作库

def run_cmd(cmd):
    print(f'>>> {cmd}')
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f'命令失败: {cmd}')
        sys.exit(result.returncode)

def build():
    if SIMULATOR == 'vcs':
        cmd = f'vcs -sverilog -ntb_opts uvm-1.2 +incdir+tb -f {FILELIST} -l compile.log'
    elif SIMULATOR == 'questa':
        cmd = f'vlib {WORK_DIR} && vlog -work {WORK_DIR} -sv +incdir+tb -f {FILELIST} -l compile.log'
    elif SIMULATOR == 'xcelium':
        cmd = f'xrun -sv -uvm +incdir+tb -f {FILELIST} -elaborate -access +rwc -l compile.log'
    else:
        print('不支持的仿真器')
        sys.exit(1)
    run_cmd(cmd)

def run(testname='fifo_base_test'):
    if SIMULATOR == 'vcs':
        cmd = f'./{SIMV} +UVM_TESTNAME={testname} -l run.log'
    elif SIMULATOR == 'questa':
        cmd = f'vsim -c -do "run -all; quit" -wlf run.wlf -sv_seed random -sv_lib {WORK_DIR} {TOP_MODULE} +UVM_TESTNAME={testname} -l run.log'
    elif SIMULATOR == 'xcelium':
        cmd = f'xrun -sv -uvm +incdir+tb -f {FILELIST} +UVM_TESTNAME={testname} -l run.log'
    else:
        print('不支持的仿真器')
        sys.exit(1)
    run_cmd(cmd)

def clean():
    for f in ['compile.log', 'run.log', SIMV, 'csrc', 'simv.daidir', 'work', 'run.wlf', 'xcelium.d', 'INCA_libs']:
        if os.path.isdir(f):
            shutil.rmtree(f, ignore_errors=True)
        elif os.path.isfile(f):
            os.remove(f)
    print('清理完成')

def main():
    if len(sys.argv) < 2:
        print('用法: python build.py [build|run|clean] [testname]')
        sys.exit(1)
    action = sys.argv[1]
    if action == 'build':
        build()
    elif action == 'run':
        testname = sys.argv[2] if len(sys.argv) > 2 else 'fifo_base_test'
        run(testname)
    elif action == 'clean':
        clean()
    else:
        print('未知命令')

if __name__ == '__main__':
    main()