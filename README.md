# ALU

基本运算单元IP的SystemVerilog实现

## IP 列表

### 公共IP

| IP           | 位置     | 描述                   |
| ------------ | -------- | ---------------------- |
| booth_radix4 | src/comm | 参数化的基4booth编码器 |
| cmprs_4to2   | src/comm | 4:2压缩器              |
| cmprs_3to2   | src/comm | 3:2压缩器(CSA)         |
| onehot_mux   | src/comm | 参数化的onehot 选择器  |

### 计算单元

| IP             | 位置        | 描述                                               |
| -------------- | ----------- | -------------------------------------------------- |
| mul_i32        | src/int/mul | 32-bit 整数乘法器，同时支持有符号数和无符号数      |
| mul_i64        | src/int/mul | 64-bit 整数乘法器，同时支持有符号数和无符号数      |
| mul_fp32       | src/fp/mul  | FP32 乘法器                                        |
| mul_fp64       | src/fp/mul  | FP64 乘法器                                       |
| div_i32_simple | src/int/div | 32-bit restoring除法器，同时支持有符号数和无符号数 |
| div_i32_srt2   | src/int/div | 32-bit SRT2 除法器，支持有符号和无符号             |
| div_i32_srt4   | src/int/div | 32-bit SRT4 除法器，支持有符号和无符号            |
| div_fp32_div   | src/fp/div  | FP32 除法器                                        |
| div_fp64_div   | src/fp/div  | FP64 除法器                                       |
| div_fp32_add   | src/fp/add  | FP32加减法器                                       |
| div_fp64_sub   | src/fp/add  | FP64加减法器                                       |
