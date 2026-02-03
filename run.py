import os
import sys
import subprocess
import shutil

# 仿真器选择: 'vcs', 'questa', 'xcelium'
SIMULATOR = 'questa'  # 可修改为 'questa' 或 'xcelium'

# 文件列表
FILELIST = 'filelist.f'
TOP_MODULE = 'tb_top'
SIMV = 'questa'  # MODELSIM 默认输出
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

def run(testname='fifo_base_test', gui=False, verbosity='UVM_LOW'):
    if SIMULATOR == 'vcs':
        cmd = f'./{SIMV} +UVM_TESTNAME={testname} +UVM_VERBOSITY={verbosity} -l run.log'
    elif SIMULATOR == 'questa':
        if gui:
            # GUI模式 - 打开波形窗口
            cmd = f'vsim -gui -wlf run.wlf -do "log -r /*; run -all" -sv_seed random {TOP_MODULE} +UVM_TESTNAME={testname} +UVM_VERBOSITY={verbosity} -l run.log'
        else:
            # 命令行模式 - 也记录所有信号波形
            cmd = f'vsim -c -do "log -r /*; run -all; quit" -wlf run.wlf -sv_seed random {TOP_MODULE} +UVM_TESTNAME={testname} +UVM_VERBOSITY={verbosity} -l run.log'
    elif SIMULATOR == 'xcelium':
        cmd = f'xrun -sv -uvm +incdir+tb -f {FILELIST} +UVM_TESTNAME={testname} +UVM_VERBOSITY={verbosity} -l run.log'
    else:
        print('不支持的仿真器')
        sys.exit(1)
    run_cmd(cmd)

def wave(wlf_file='run.wlf'):
    """打开已有的波形文件"""
    if not os.path.exists(wlf_file):
        print(f'错误: 波形文件 {wlf_file} 不存在')
        print('请先运行仿真生成波形文件')
        sys.exit(1)
    if SIMULATOR == 'questa':
        cmd = f'vsim -view {wlf_file}'
    else:
        print('wave命令目前只支持Questa/ModelSim')
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
        print('用法: python run.py [build|run|wave|clean] [testname] [--gui] [--verbosity=UVM_LOW]')
        print('示例:')
        print('  python run.py build')
        print('  python run.py run fifo_base_test')
        print('  python run.py run fifo_base_test --gui  # GUI模式，打开波形')
        print('  python run.py run fifo_base_test --verbosity=UVM_HIGH')
        print('  python run.py wave                      # 打开已有波形文件 run.wlf')
        print('  python run.py wave my_wave.wlf          # 打开指定波形文件')
        print('  python run.py clean')
        sys.exit(1)
    action = sys.argv[1]
    if action == 'build':
        build()
    elif action == 'run':
        testname = sys.argv[2] if len(sys.argv) > 2 else 'fifo_base_test'
        gui = '--gui' in sys.argv
        verbosity = 'UVM_LOW'
        for arg in sys.argv:
            if arg.startswith('--verbosity='):
                verbosity = arg.split('=', 1)[1]
        run(testname, gui, verbosity)
    elif action == 'wave':
        wlf_file = sys.argv[2] if len(sys.argv) > 2 else 'run.wlf'
        wave(wlf_file)
    elif action == 'clean':
        clean()
    else:
        print('未知命令')

if __name__ == '__main__':
    main()