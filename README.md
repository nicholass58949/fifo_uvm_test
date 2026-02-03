# Async FIFO UVM 验证平台

一个基于 UVM (Universal Verification Methodology) 的异步 FIFO 芯片验证框架，包括完整的验证环境、参考模型、计分板和测试用例。

## 📋 目录结构

```
base_framework/
├── rtl/
│   └── async_fifo.sv                # DUT - 异步FIFO设计
│
├── tb/                              # 测试平台
│   ├── fifo_pkg.sv                  # UVM包 - 包含所有验证组件定义
│   ├── tb_top.sv                    # 顶层测试平台
│   │
│   ├── common/                      # 公共组件
│   │   ├── fifo_interface.sv        # FIFO VIF接口定义
│   │   ├── fifo_transaction.sv      # 事务类定义
│   │   ├── fifo_assertions.sv       # 断言集合
│   │   └── fifo_coverage.sv         # 覆盖率定义
│   │
│   ├── agents/                      # Agent集合
│   │   ├── reset_sequence.sv        # 复位序列
│   │   ├── master/                  # Master Agent (写端口)
│   │   │   ├── master_agent.sv
│   │   │   ├── master_driver.sv     # 驱动写数据
│   │   │   ├── master_monitor.sv    # 采集写端口信号
│   │   │   ├── master_sequencer.sv  # 序列生成器
│   │   │   └── master_sequence.sv   # 数据序列
│   │   │
│   │   └── slave/                   # Slave Agent (读端口)
│   │       ├── slave_agent.sv
│   │       ├── slave_driver.sv      # 驱动读请求
│   │       ├── slave_monitor.sv     # 采集读端口信号
│   │       ├── slave_sequencer.sv   # 序列生成器
│   │       └── slave_sequence.sv    # 读请求序列
│   │
│   ├── env/                         # 验证环境
│   │   ├── fifo_env.sv              # 顶层环境 - 整合所有Agent
│   │   ├── fifo_reference_model.sv  # 参考模型 - 实现FIFO行为
│   │   └── fifo_scoreboard.sv       # 计分板 - 比较预期值和实际值
│   │
│   └── tests/                       # 测试用例
│       ├── fifo_test.sv             # 基础测试
│       └── fifo_reset_test.sv       # 复位测试
│
├── filelist.f                       # 编译文件列表
├── run.py                           # Python运行脚本
└── README.md                        # 项目文档
```

## 🏗️ 架构说明

### 数据流图

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          fifo_env 验证环境                                │
│                                                                            │
│  ┌─────────────────┐                              ┌──────────────────┐  │
│  │  Master Agent   │  ──写数据──────────────────►  │ Reference Model  │  │
│  │   (写端口)      │                              │  (FIFO参考实现)  │  │
│  │ Driver/Monitor  │                              └────────┬─────────┘  │
│  └─────────────────┘                                       │ 期望数据   │
│                                                             │            │
│                                                             ▼            │
│                                                    ┌──────────────────┐  │
│  ┌─────────────────┐                              │   Scoreboard     │  │
│  │  Slave Agent    │  ──实际读数据──────────────►  │ (期望 vs 实际)  │  │
│  │   (读端口)      │                              └──────────────────┘  │
│  │ Driver/Monitor  │                                                    │
│  └─────────────────┘                                                    │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
                                    ▲
                                    │
                            ┌───────┴──────┐
                            │  Async FIFO  │
                            │     DUT      │
                            └──────────────┘
```

### 核心组件说明

#### 1. **Master Agent (主机代理)**
- **功能**: 负责FIFO写端口的数据驱动和监测
- **子组件**:
  - `master_driver`: 根据`full`信号驱动数据写入
  - `master_monitor`: 采集写操作信号，发送给参考模型
  - `master_sequence`: 生成写数据序列（随机/定序）

#### 2. **Slave Agent (从机代理)**
- **功能**: 负责FIFO读端口的请求驱动和数据采集
- **子组件**:
  - `slave_driver`: 根据`empty`信号发送读请求
  - `slave_monitor`: 采集读返回的数据，发送给计分板
  - `slave_sequence`: 生成读请求序列

#### 3. **Reference Model (参考模型)**
- **功能**: 实现期望的FIFO行为
- **实现**: 使用简单的SystemVerilog队列(queue)
- **作用**: 与Master Agent输入同步，为Scoreboard提供期望数据

#### 4. **Scoreboard (计分板)**
- **功能**: 比较DUT实际输出与参考模型的期望输出
- **检查**: 
  - 数据正确性
  - FIFO顺序正确性
  - 边界条件(空/满)处理

#### 5. **Assertions (断言)**
- **功能**: 在线监控DUT行为的正确性
- **检查内容**: 协议合法性、超时检测等
   - 接收参考模型和Slave Agent的数据
   - 比较预期值和实际值
   - 统计match和mismatch数量

## 🚀 快速开始

### 前置条件
- 已安装仿真工具 (VCS, Questa/ModelSim, 或 Xcelium)
- 已安装 UVM 库
- Python 3.x (用于运行脚本)

### 编译和运行

#### 方法1: 使用Python脚本 (推荐)

```bash
# 编译设计和测试平台
python run.py build

# 运行默认测试
python run.py run

# 运行指定测试（GUI模式）
python run.py run --gui --testname fifo_base_test

# 运行带特定序列的测试
python run.py run --testname fifo_base_test --verbosity UVM_HIGH
```

#### 方法2: 使用Questa (命令行)

```bash
# 编译
vlib work
vlog -work work -sv +incdir+tb -f filelist.f

# 运行
vsim -c -work work tb_top +UVM_TESTNAME=fifo_base_test -do "run -all; quit"

# GUI运行
vsim -gui -work work tb_top +UVM_TESTNAME=fifo_base_test
```

#### 方法3: 使用VCS ( 命令行)

```bash
# 编译和链接
vcs -sverilog -ntb_opts uvm-1.2 +incdir+tb -f filelist.f -o simv

# 运行
./simv +UVM_TESTNAME=fifo_base_test +UVM_VERBOSITY=UVM_LOW
```

#### 方法4: 使用Xcelium (命令行)

```bash
xrun -sv -uvm +incdir+tb -f filelist.f +UVM_TESTNAME=fifo_base_test -l run.log
```

## 🧪 可用测试用例

| 测试名称 | 说明 | 重点 |
|---------|------|------|
| `fifo_test` | 基本功能测试 | 随机写读操作 |
| `fifo_reset_test` | 复位测试 | 各种复位场景 |
| `fifo_stress_test` | 压力测试（可选） | 大数据量、多个时钟周期 |
| `fifo_coverage_test` | 覆盖率测试（可选） | 所有功能覆盖 |

### 运行特定测试

```bash
python run.py run --testname fifo_reset_test --verbosity UVM_MEDIUM
```

## ✅ 验证方法

### 1. 断言检查 (Assertions)

断言模块 (`fifo_assertions.sv`) 在线监控以下行为：

| 断言 | 说明 | 触发条件 |
|------|------|---------|
| `wr_full_check` | FIFO满时不应写 | `wr_en && full` |
| `rd_empty_check` | FIFO空时不应读 | `rd_en && empty` |
| `full_empty_check` | 不能同时满和空 | `full && empty` |
| `reset_check` | 复位后应为空 | 复位后`empty=1` |

### 2. 计分板检查 (Scoreboard)

- **数据一致性**: 验证读出数据与写入数据一致
- **FIFO顺序**: 确保FIFO遵循先进先出原则
- **覆盖率统计**: 统计成功操作数、错误检测数

### 3. 覆盖率收集 (Coverage)

覆盖率模块 (`fifo_coverage.sv`) 收集以下覆盖点：

```
覆盖组 (Covergroup):
├── write_coverage       # 写操作覆盖
│   ├── wr_en_high      # 写使能为1
│   ├── wr_en_low       # 写使能为0
│   └── full_coverage   # full状态
├── read_coverage        # 读操作覆盖
│   ├── rd_en_high      # 读使能为1
│   ├── rd_en_low       # 读使能为0
│   └── empty_coverage  # empty状态
└── state_coverage       # 状态转换覆盖
    ├── empty_to_full   # 空→满转换
    ├── full_to_empty   # 满→空转换
    └── partial_fill    # 部分填满
```

1. **cg_write_port** - 写端口覆盖（写使能、满标志、数据范围）
2. **cg_read_port** - 读端口覆盖（读使能、空标志、数据范围）
3. **cg_fifo_depth** - FIFO深度覆盖（0-16所有深度、深度转换）
4. **cg_reset** - 复位覆盖（独立复位、同时复位）

## ⚙️ 参数配置

主要参数定义在 [tb/fifo_pkg.sv](tb/fifo_pkg.sv) 中：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `DATA_WIDTH` | 8 | 数据位宽 |
| `ADDR_WIDTH` | 4 | 地址位宽（决定FIFO深度 = 2^ADDR_WIDTH） |
| `WR_CLK_PERIOD` | 10 | 写时钟周期(ns) |
| `RD_CLK_PERIOD` | 15 | 读时钟周期(ns) |

### 修改参数

在仿真命令中使用 `+define+` 覆盖默认参数：

```bash
# Questa
vsim -c tb_top +define+DATA_WIDTH=16 +define+ADDR_WIDTH=5 -do "run -all"

# VCS
./simv +define+DATA_WIDTH=16 +define+ADDR_WIDTH=5

# Xcelium
xrun -sv -uvm +define+DATA_WIDTH=16 +define+ADDR_WIDTH=5 -f filelist.f
```

## 📊 结果查看

### 1. 仿真日志

```bash
# 查看运行日志
cat run.log

# 查看编译日志
cat compile.log
```

### 2. 波形文件

- **Questa**: `run.wlf` - 使用 `vsim -gui` 打开
- **VCS**: `vcdplus.vpd` 或 `dump.vcd` - 使用波形查看工具打开
- **Xcelium**: `xcelium.d/xcelium.so` 或 `waveform.shm`

### 3. 覆盖率报告

```bash
# Questa覆盖率
vsim -gui work.tb_top -do "coverage report -verbose"

# VCS覆盖率
urgereport -dir simv.vdb -report report.txt
```

## 📝 开发和扩展

### 添加新测试

在 `tb/tests/` 文件夹中创建新的测试文件：

```systemverilog
class my_custom_test extends fifo_base_test;
    `uvm_component_utils(my_custom_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // 自定义配置
    endfunction
endclass
```

### 添加自定义序列

在 `tb/agents/master/` 或 `tb/agents/slave/` 中创建：

```systemverilog
class custom_sequence extends fifo_transaction;
    `uvm_object_utils(custom_sequence)
    
    constraint data_constraint {
        data inside {[0:255]};
    }
    
    function new(string name="custom_sequence");
        super.new(name);
    endfunction
endclass
```

### 修改参考模型

编辑 [tb/env/fifo_reference_model.sv](tb/env/fifo_reference_model.sv)：

```systemverilog
// 在handle_write任务中实现自定义逻辑
task handle_write(input fifo_transaction tr);
    if (q.size() < MAX_DEPTH) begin
        q.push_back(tr.data);
    end
endtask
```

## 🔍 常见问题排查

### 编译错误

1. **找不到UVM库**
   ```bash
   # 检查UVM_HOME环境变量
   echo $UVM_HOME
   
   # 或手动指定
   vlog -sv $UVM_HOME/src/uvm_pkg.sv
   ```

2. **找不到自定义文件**
   - 检查 `filelist.f` 中的路径是否正确
   - 确保使用了 `+incdir+tb`

### 运行错误

1. **测试不运行**
   ```bash
   # 检查测试名称是否存在
   grep -r "class.*extends uvm_test" tb/tests/
   
   # 查看仿真输出
   cat run.log | grep -i error
   ```

2. **Scoreboard报告错误**
   - 检查 `fifo_reference_model.sv` 的FIFO实现
   - 确保Master/Slave Agent的monitor正确采集信号

3. **断言失败**
   - 查看DUT设计是否有bug
   - 检查约束条件是否过于严格

## 📚 文件说明速查

| 文件 | 主要功能 | 修改频率 |
|------|---------|--------|
| [rtl/async_fifo.sv](rtl/async_fifo.sv) | DUT设计 | 常修改 |
| [tb/fifo_pkg.sv](tb/fifo_pkg.sv) | 包定义与参数 | 常修改 |
| [tb/tb_top.sv](tb/tb_top.sv) | 顶层连接 | 偶修改 |
| [tb/common/fifo_interface.sv](tb/common/fifo_interface.sv) | VIF定义 | 极少修改 |
| [tb/common/fifo_transaction.sv](tb/common/fifo_transaction.sv) | 事务类 | 偶修改 |
| [tb/agents/master/master_driver.sv](tb/agents/master/master_driver.sv) | 写驱动 | 常修改 |
| [tb/agents/slave/slave_driver.sv](tb/agents/slave/slave_driver.sv) | 读驱动 | 常修改 |
| [tb/env/fifo_reference_model.sv](tb/env/fifo_reference_model.sv) | 参考模型 | 常修改 |
| [tb/env/fifo_scoreboard.sv](tb/env/fifo_scoreboard.sv) | 计分板 | 偶修改 |
| [tb/tests/fifo_test.sv](tb/tests/fifo_test.sv) | 基础测试 | 常修改 |

## 🤝 贡献指南

1. **代码风格**
   - 使用UVM编码规范
   - 关键变量添加注释说明
   - 函数添加文档注释

2. **测试要求**
   - 新功能必须有对应测试用例
   - 测试覆盖率不低于80%
   - 所有断言应该通过

3. **提交PR**
   - 清晰描述改动内容
   - 包含测试结果报告
   - 更新README文档

## 📞 支持

如有问题，请检查：
1. 仿真工具版本兼容性
2. 文件路径和编码格式
3. UVM库版本一致性
4. Systemverilog语法规范

---

**最后更新**: 2026年2月  
**维护者**: UVM验证团队
