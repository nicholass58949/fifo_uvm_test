# Async FIFO UVM Verification Platform

## 项目结构

```
base_framework/
├── rtl/
│   └── async_fifo.sv           # 异步FIFO DUT
│
├── tb/
│   ├── fifo_pkg.sv             # UVM包文件
│   ├── tb_top.sv               # 顶层测试平台
│   │
│   ├── common/
│   │   ├── fifo_interface.sv   # FIFO接口定义
│   │   └── fifo_transaction.sv # 事务类
│   │
│   ├── agents/
│   │   ├── master/             # Master Agent (写端口)
│   │   │   ├── master_agent.sv
│   │   │   ├── master_driver.sv
│   │   │   ├── master_monitor.sv
│   │   │   ├── master_sequencer.sv
│   │   │   └── master_sequence.sv
│   │   │
│   │   └── slave/              # Slave Agent (读端口)
│   │       ├── slave_agent.sv
│   │       ├── slave_driver.sv
│   │       ├── slave_monitor.sv
│   │       ├── slave_sequencer.sv
│   │       └── slave_sequence.sv
│   │
│   ├── env/
│   │   ├── fifo_env.sv             # 验证环境
│   │   ├── fifo_reference_model.sv # 参考模型(简单队列)
│   │   └── fifo_scoreboard.sv      # 计分板
│   │
│   └── tests/
│       └── fifo_test.sv            # 测试用例
│
├── filelist.f                  # 文件列表
└── README.md                   # 说明文档
```

## 架构说明

### 数据流

```
                          ┌─────────────────────────────────────────────────┐
                          │                    fifo_env                      │
                          │                                                  │
┌──────────┐              │  ┌─────────────────┐    ┌───────────────────┐   │
│  Master  │──wr_data────►│  │  Master Agent   │    │  Reference Model  │   │
│ Sequence │              │  │   (Write Port)  │───►│  (Simple Queue)   │   │
└──────────┘              │  │  Driver/Monitor │    │                   │   │
                          │  └─────────────────┘    └─────────┬─────────┘   │
                          │                                   │ exp_data    │
                          │                                   ▼             │
                          │                           ┌───────────────────┐ │
                          │                           │    Scoreboard     │ │
                          │                           │ (Compare exp/act) │ │
                          │                           └───────────────────┘ │
                          │                                   ▲             │
                          │  ┌─────────────────┐              │ act_data    │
┌──────────┐              │  │  Slave Agent    │──────────────┘             │
│  Slave   │──rd_req─────►│  │   (Read Port)   │                            │
│ Sequence │              │  │  Driver/Monitor │                            │
└──────────┘              │  └─────────────────┘                            │
                          │                                                  │
                          └──────────────────────────────────────────────────┘
                                              ▲
                                              │
                                       ┌──────┴──────┐
                                       │  Async FIFO │
                                       │    (DUT)    │
                                       └─────────────┘
```

### 组件说明

1. **Master Agent (主机代理)**
   - 负责FIFO写端口
   - `master_driver`: 根据full信号驱动写数据
   - `master_monitor`: 采集写数据发送给参考模型
   - `master_sequence`: 生成随机或固定写数据

2. **Slave Agent (从机代理)**
   - 负责FIFO读端口
   - `slave_driver`: 根据empty信号发送读请求
   - `slave_monitor`: 采集实际读数据发送给计分板
   - `slave_sequence`: 生成读请求

3. **Reference Model (参考模型)**
   - 实现简单的FIFO队列功能
   - 接收master_monitor的写数据
   - 提供期望数据给scoreboard

4. **Scoreboard (计分板)**
   - 接收slave_monitor的实际数据
   - 从参考模型获取期望数据
   - 比较并统计匹配/不匹配数量

## 仿真命令

### 使用VCS

```bash
vcs -sverilog -ntb_opts uvm-1.2 +incdir+tb -f filelist.f -o simv
./simv +UVM_TESTNAME=fifo_base_test
```

### 使用Questa/ModelSim

```bash
vlog -sv +incdir+$UVM_HOME/src +incdir+tb $UVM_HOME/src/uvm_pkg.sv -f filelist.f
vsim -c tb_top +UVM_TESTNAME=fifo_base_test -do "run -all"
```

### 使用Xcelium

```bash
xrun -sv -uvm +incdir+tb -f filelist.f +UVM_TESTNAME=fifo_base_test
```

## 可用测试用例

1. **fifo_base_test** - 基本功能测试，随机数据
2. **fifo_fixed_test** - 固定数据测试，用于调试
3. **fifo_stress_test** - 压力测试，大量数据
4. **fifo_reset_test** - 复位测试，测试写/读/同时复位
5. **fifo_async_reset_test** - 异步复位测试，测试不同时间释放复位

## 断言检查

断言模块 (`fifo_assertions.sv`) 包含以下检查：

1. **复位断言**
   - 复位时full应该为低
   - 复位时empty应该为高

2. **操作断言**
   - FIFO满时不应写入
   - FIFO空时不应读取
   - full和empty不能同时为高

3. **覆盖属性**
   - 成功写入/读取
   - 满/空时尝试操作
   - 状态转换（空→非空，满→非满）

## 覆盖率收集

覆盖率模块 (`fifo_coverage.sv`) 包含以下覆盖组：

1. **cg_write_port** - 写端口覆盖（写使能、满标志、数据范围）
2. **cg_read_port** - 读端口覆盖（读使能、空标志、数据范围）
3. **cg_fifo_depth** - FIFO深度覆盖（0-16所有深度、深度转换）
4. **cg_reset** - 复位覆盖（独立复位、同时复位）

## 参数配置

- `DATA_WIDTH`: 数据位宽，默认8位
- `ADDR_WIDTH`: 地址位宽，默认4位（FIFO深度=16）
- `WR_CLK_PERIOD`: 写时钟周期，默认10ns
- `RD_CLK_PERIOD`: 读时钟周期，默认15ns
