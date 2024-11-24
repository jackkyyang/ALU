/*
   Copyright 2024 jackkyyang

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 ***************************************************************************
  * File Name: cmprs_tree_8to1.sv
  * Creation Date: 2024/11/17
  * Author: jackkyyang
  * Description:
  *   A tree compressor for 8-to-1.
 ***************************************************************************
*/

module cmprs_tree_8to1 #(
    parameter integer WIDTH = 8,
    parameter bit FLOP_EN = 1
)(
    input  logic             clk_i,
    input  logic             rst_n_i,
    input  logic             data_vld_i,
    input  logic [WIDTH-1:0] pp_i [7:0],
    output logic             data_vld_o,
    output logic [WIDTH+3:0] sum_o
);

logic [WIDTH-1:0] s_l1 [2:0];
logic [WIDTH-1:0] c_l1 [5:0];
logic [WIDTH-1:0] c_l2 [2:0];
logic [WIDTH-1:0] c_l3 [1:0];
logic [WIDTH-1:0] c_l4 [0];
logic [WIDTH-1:0] s_l2 [0];
logic [WIDTH-1:0] s_l3 [0];
logic [WIDTH-1:0] s_l4 [0];
logic [WIDTH-1:0] add_result;

// L1 compressor
cmprs_4to2 #(
    .WIDTH(WIDTH)
) u_l1_0 (
    .cin({WIDTH{1'b0}}),
    .a(pp_i[0][WIDTH-1:0]),
    .b(pp_i[1][WIDTH-1:0]),
    .c(pp_i[2][WIDTH-1:0]),
    .d(pp_i[3][WIDTH-1:0]),
    .cout_a(c_l1[0][WIDTH-1:0]),
    .cout_b(c_l1[1][WIDTH-1:0]),
    .sum(s_l1[0][WIDTH-1:0])
);

cmprs_4to2 #(
    .WIDTH(WIDTH)
) u_l1_1 (
    .cin({WIDTH{1'b0}}),
    .a(pp_i[4][WIDTH-1:0]),
    .b(pp_i[5][WIDTH-1:0]),
    .c(pp_i[6][WIDTH-1:0]),
    .d(pp_i[7][WIDTH-1:0]),
    .cout_a(c_l1[2][WIDTH-1:0]),
    .cout_b(c_l1[3][WIDTH-1:0]),
    .sum(s_l1[1][WIDTH-1:0])
);

// L2 compressor
cmprs_2to1 #(
    .WIDTH(WIDTH)
) u_l2_0 (
    .a(s_l1[0][WIDTH-1:0]),
    .b(s_l1[1][WIDTH-1:0]),
    .cout(c_l1[4][WIDTH-1:0]), // carry out of l2 2to1
    .sum(s_l1[2][WIDTH-1:0])
);

cmprs_4to2 #(
    .WIDTH(WIDTH)
) u_l2_1 (
    .cin({WIDTH{1'b0}}),
    .a(c_l1[0][WIDTH-1:0]),
    .b(c_l1[1][WIDTH-1:0]),
    .c(c_l1[2][WIDTH-1:0]),
    .d(c_l1[3][WIDTH-1:0]),
    .cout_a(c_l2[0][WIDTH-1:0]),
    .cout_b(c_l2[1][WIDTH-1:0]),
    .sum(c_l1[5][WIDTH-1:0])  // sum of l2 4to2
);

cmprs_3to2 #(
    .WIDTH(WIDTH)
) u_l2_2 (
    .a(c_l1[4][WIDTH-1:0]),
    .b(c_l1[5][WIDTH-1:0]),
    .c({1'b0,s_l1[2][WIDTH-1:1]}),
    .cout(c_l2[2][WIDTH-1:0]), // the carry out of l2 3to2
    .sum(s_l2[0][WIDTH-1:0])
);

// L3 compressor
cmprs_4to2 #(
    .WIDTH(WIDTH)
) u_l3_0 (
    .cin({WIDTH{1'b0}}),
    .a(c_l2[0][WIDTH-1:0]),
    .b(c_l2[1][WIDTH-1:0]),
    .c(c_l2[2][WIDTH-1:0]),
    .d({1'b0,s_l2[0][WIDTH-1:1]}),
    .cout_a(c_l3[0][WIDTH-1:0]),
    .cout_b(c_l3[1][WIDTH-1:0]),
    .sum(s_l3[0][WIDTH-1:0])  // sum of l2 4to2
);

// L4 compressor
cmprs_3to2 #(
    .WIDTH(WIDTH)
) u_l3_1 (
    .a(c_l3[0][WIDTH-1:0]),
    .b(c_l3[1][WIDTH-1:0]),
    .c({1'b0,s_l3[0][WIDTH-1:1]}),
    .cout(c_l4[0][WIDTH-1:0]), // the carry out of l2 3to2
    .sum(s_l4[0][WIDTH-1:0])
);


generate
    if (FLOP_EN) begin:gen_flop

        logic [WIDTH-1:0] c_l4_ff;
        logic [WIDTH-1:0] s_l4_ff;
        logic s_l3_0_ff;
        logic s_l2_0_ff;
        logic s_l1_2_ff;

        always_ff @(posedge clk_i or negedge rst_n_i) begin
            if (!rst_n_i) begin
                data_vld_o <= 1'b0;
            end
            else begin
                data_vld_o <= data_vld_i;
            end
        end

        always_ff @(posedge clk_i) begin
            if (data_vld_i) begin
                c_l4_ff <= c_l4[0][WIDTH-1:0];
                s_l4_ff <= s_l4[0][WIDTH-1:0];
                s_l3_0_ff <= s_l3[0][0];
                s_l2_0_ff <= s_l2[0][0];
                s_l1_2_ff <= s_l1[2][0];
            end
        end
        assign add_result[WIDTH-1:0] = c_l4_ff[WIDTH-1:0] + {1'b0,s_l4_ff[WIDTH-1:1]};
        assign sum_o = {
            add_result[WIDTH-1:0],
            s_l4_ff[0],
            s_l3_0_ff,
            s_l2_0_ff,
            s_l1_2_ff
        };


    end
    else begin:gen_no_flop
        // final adder
        assign data_vld_o            = data_vld_i;
        assign add_result[WIDTH-1:0] = c_l4[0][WIDTH-1:0] + {1'b0,s_l4[0][WIDTH-1:1]};
        assign sum_o = {
            add_result[WIDTH-1:0],
            s_l4[0][0],
            s_l3[0][0],
            s_l2[0][0],
            s_l1[2][0]
        };
    end
endgenerate




endmodule
