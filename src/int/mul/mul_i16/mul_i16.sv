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
  * File Name: mul_i32.sv
  * Creation Date: 2024/10/27
  * Author: jackkyyang
  * Description:
  *   A multiplier for 32-bit signed/unsigned integer.
 ***************************************************************************
*/

module mul_i16 #(
    parameter bit FLOP_EN = 0,
    localparam integer WIDTH  = 16,
    localparam integer C_WIDTH    = WIDTH * 2
)(
    input  logic                clk_i,
    input  logic                rst_n_i,
    input  logic [WIDTH-1:0]    a_i,
    input  logic [WIDTH-1:0]    b_i,
    input  logic                data_vld_i,
    input  logic                is_signed_i,
    output logic                data_vld_o,
    output logic [C_WIDTH-1:0]  c_o
);

  localparam integer EXT_WIDTH  = (WIDTH + 2);
  localparam integer PP_NUM     = EXT_WIDTH/2;

  // extend the a and b to signed format
  logic [EXT_WIDTH-1:0] a_ext;
  logic [EXT_WIDTH-1:0] b_ext;
  // the partial product of a
  logic [EXT_WIDTH-1:0] a_neg_2x;
  logic [EXT_WIDTH-1:0] a_neg_1x;
  logic [EXT_WIDTH-1:0] a_pos_2x;
  logic [EXT_WIDTH-1:0] a_pos_1x;

  logic [EXT_WIDTH-1:0] a_pp_src    [3:0];
  logic [EXT_WIDTH-1:0] a_pp        [PP_NUM-1:0];
  logic [C_WIDTH:0]     a_pp_ext    [PP_NUM-1:0];
  logic [1:0]           neg_c       [PP_NUM-1:0];
  logic [3:0]           pp_sel      [PP_NUM-1:0];


  assign a_ext    = is_signed_i ? {a_i[WIDTH-1], a_i[WIDTH-1], a_i[WIDTH-1:0]} : {2'b0, a_i};
  assign b_ext    = is_signed_i ? {b_i[WIDTH-1], b_i[WIDTH-1], b_i[WIDTH-1:0]} : {2'b0, b_i};

  assign a_neg_1x = ~a_ext;
  assign a_neg_2x = {~a_ext[EXT_WIDTH-2:0],1'b0};
  assign a_pos_1x = a_ext;
  assign a_pos_2x = {a_ext[EXT_WIDTH-2:0],1'b0};

  assign a_pp_src[3] = a_neg_2x;
  assign a_pp_src[2] = a_neg_1x;
  assign a_pp_src[1] = a_pos_2x;
  assign a_pp_src[0] = a_pos_1x;

  generate
    for (genvar i = 0; i < PP_NUM; i += 1) begin : gen_booth_pp
      onehot_mux #(
          .T(logic [EXT_WIDTH-1:0]),
          .SEL_WIDTH(4)
      ) u_pp_mux (
          .sel_oh_i(pp_sel[i]),
          .data_i  (a_pp_src),
          .data_o  (a_pp[i])
      );

    end
  endgenerate

  booth_radix4 #(
      .WIDTH(EXT_WIDTH),
      .PP_NUM(PP_NUM)
  ) u_booth_enc (
      .data_sign_ext_i(b_ext),
      .pp_sel_o(pp_sel),
      .neg_c_o(neg_c)
  );

  // arrange the partial product
  // refer to Digital Arithmetic(Chapter 4.2.1), Ercegovac.
  assign a_pp_ext[0] = {{(WIDTH-3){1'b0}},
                        ~a_pp[0][EXT_WIDTH-1],
                        a_pp[0][EXT_WIDTH-1],
                        a_pp[0]
                       };
  assign a_pp_ext[1] = {{(WIDTH-4){1'b0}},
                        1'b1,
                        ~a_pp[1][EXT_WIDTH-1],
                        a_pp[1][EXT_WIDTH-2:0],
                        neg_c[0]
                       };

  generate
    for (genvar i = 2; i < PP_NUM - 1; i += 1) begin : gen_pp_ext
      assign a_pp_ext[i] = {
        {(WIDTH - 4 - ((i - 1) * 2)){1'b0}},
        1'b1,
        ~a_pp[i][EXT_WIDTH-1],
        a_pp[i][EXT_WIDTH-2:0],
        neg_c[i-1],
        {((i - 1) * 2) {1'b0}}
      };
    end
  endgenerate

  assign a_pp_ext[PP_NUM-1] = {a_pp[PP_NUM-1][EXT_WIDTH-2:0],
                               neg_c[PP_NUM-2],
                               {(WIDTH-2){1'b0}}
                              };

//======================================
// 9-to-1 compress tree
//======================================

// L1 compressor
logic [25:1] l1_0_cout [1:0];
logic [24:0] l1_0_sum ;
cmprs_4to2 #(
    .WIDTH(25)
) u_l1_0 (
    .cin(25'd0),
    .a(a_pp_ext[0][24:0]),
    .b(a_pp_ext[1][24:0]),
    .c(a_pp_ext[2][24:0]),
    .d(a_pp_ext[3][24:0]),
    .cout_a(l1_0_cout[0][25:1]),
    .cout_b(l1_0_cout[1][25:1]),
    .sum(l1_0_sum[24:0])
);

logic [33:7] l1_1_cout [1:0];
logic [32:6] l1_1_sum ;

cmprs_4to2 #(
    .WIDTH(27)
) u_l1_1 (
    .cin(27'd0),
    .a(a_pp_ext[4][32:6]),
    .b(a_pp_ext[5][32:6]),
    .c(a_pp_ext[6][32:6]),
    .d(a_pp_ext[7][32:6]),
    .cout_a(l1_1_cout[0][33:7]),
    .cout_b(l1_1_cout[1][33:7]),
    .sum(l1_1_sum[32:6])
);

// L2 compressor
logic [26:2] l2_0_cout;
logic [25:1] l2_0_sum ;
cmprs_3to2 #(
    .WIDTH(25)
) u_l2_0 (
    .a(l1_0_cout[0][25:1]),
    .b(l1_0_cout[1][25:1]),
    .c({1'b0,l1_0_sum[24:1]}),
    .cout(l2_0_cout[26:2]), // the carry out of l2 3to2
    .sum(l2_0_sum[25:1])
);

logic [33:7] l2_1_cout;
logic [32:6] l2_1_sum ;
cmprs_3to2 #(
    .WIDTH(27)
) u_l2_1 (
    .a({l1_1_cout[0][32:7],1'b0}),
    .b({l1_1_cout[1][32:7],1'b0}),
    .c(l1_1_sum[32:6]),
    .cout(l2_1_cout[33:7]), // the carry out of l2 3to2
    .sum(l2_1_sum[32:6])
);

// L3 compressor
logic [33:3] l3_0_cout [1:0];
logic [32:2] l3_0_sum ;
cmprs_4to2 #(
    .WIDTH(31)
) u_l3 (
    .cin({a_pp_ext[8][32:6],4'd0}),
    .a({6'd0,l2_0_cout[26:2]}),
    .b({7'd0,l2_0_sum[25:2]}),
    .c({l2_1_cout[32:7],5'd0}),
    .d({l2_1_sum[32:6],4'd0}),
    .cout_a(l3_0_cout[0][33:3]),
    .cout_b(l3_0_cout[1][33:3]),
    .sum(l3_0_sum[32:2])
);

// L4 compressor
logic [33:4] l4_cout;
logic [32:3] l4_sum;
cmprs_3to2 #(
    .WIDTH(30)
) u_l4 (
    .a(l3_0_cout[0][32:3]),
    .b(l3_0_cout[1][32:3]),
    .c(l3_0_sum[32:3]),
    .cout(l4_cout[33:4]), // the carry out of l2 3to2
    .sum(l4_sum[32:3])
);

generate
  if (FLOP_EN) begin:gen_flop
    logic [31:4] l4_sum_ff;
    logic [31:4] l4_cout_ff;
    logic [3:0]  sum_low_bits_ff;

    always_ff @( posedge clk_i ) begin
      if (data_vld_i) begin
        l4_sum_ff <= l4_sum[31:4];
        l4_cout_ff <= l4_cout[31:4];
        sum_low_bits_ff <= {l4_sum[4],l3_0_sum[2],l2_0_sum[1],l1_0_sum[0]};
      end
    end

    wire [31:4] final_add = l4_sum_ff + l4_cout_ff;
    assign c_o = {final_add,sum_low_bits_ff};
    always_ff @( posedge clk_i or negedge rst_n_i) begin
      if (!rst_n_i) begin
        data_vld_o <= 1'b0;
      end else begin
        data_vld_o <= data_vld_i;
      end
    end
  end
  else begin:gen_no_flop
    wire [31:4] final_add = l4_sum[31:4] + l4_cout[31:4];
    assign c_o = {final_add,l4_sum[3],l3_0_sum[2],l2_0_sum[1],l1_0_sum[0]};
    assign data_vld_o = data_vld_i;
  end
endgenerate


endmodule
