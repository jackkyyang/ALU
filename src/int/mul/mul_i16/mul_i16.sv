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
  logic [C_WIDTH-1:0]   a_pp_x    [PP_NUM-1:0];
  logic [1:0]           neg_c       [PP_NUM-1:0];
  logic [3:0]           pp_sel      [PP_NUM-1:0];


  assign a_ext    = is_signed_i ? {a_i[WIDTH], a_i[WIDTH], a_i[WIDTH-1:0]} : {2'b0, a_i};
  assign b_ext    = is_signed_i ? {b_i[WIDTH], b_i[WIDTH], b_i[WIDTH-1:0]} : {2'b0, b_i};

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

      assign a_pp_x[i] = a_pp_ext[i][C_WIDTH-1:0];
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
// 8-to-1 compress tree
//======================================

logic [C_WIDTH+3:0] cmprs_sum_o;

cmprs_tree_8to1
#(
    .WIDTH   (C_WIDTH),
    .FLOP_EN (FLOP_EN )
)
u_cmprs_tree_8to1(
    .clk_i      (clk_i      ),
    .rst_n_i    (rst_n_i    ),
    .data_vld_i (data_vld_i ),
    .pp_i       (a_pp_x[7:0]),
    .data_vld_o (data_vld_o ),
    .sum_o      (cmprs_sum_o      )
);

generate
  if (FLOP_EN) begin:gen_flop
    logic [C_WIDTH-1:0] pp_8_ff;

    always_ff @( clk_i ) begin
      if (data_vld_i) begin
        pp_8_ff <= a_pp_ext[8][C_WIDTH-1:0];
      end
    end

    assign c_o = pp_8_ff[C_WIDTH-1:0] + cmprs_sum_o[C_WIDTH-1:0];
  end
  else begin:gen_no_flop
    assign c_o = a_pp_ext[8][C_WIDTH-1:0] + cmprs_sum_o[C_WIDTH-1:0];
  end
endgenerate

endmodule
