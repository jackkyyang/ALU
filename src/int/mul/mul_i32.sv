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
  *   A multipler for 32-bit signed/unsgined integer.
 ***************************************************************************
*/

module mul_i32
  import alu_comm_pkg::*;
(
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic        is_signed_i,
    output logic [31:0] p_o
);

  // partial product generation
  localparam integer PP_NUM = calc_pp_num(33);

  logic [3:0] pp_sel[PP_NUM-1:0];
  logic [33:0] pp[PP_NUM-1:0];
  logic [65:0] pp_ext[PP_NUM-1:0];
  logic [33:0] a_pp_src[3:0];

  logic [1:0] neg_c[PP_NUM-1:0];

  logic [32:0] a_ext;
  logic [32:0] b_ext;
  logic [33:0] a_neg_2x;
  logic [33:0] a_neg_1x;
  logic [33:0] a_pos_2x;
  logic [33:0] a_pos_1x;


  assign a_ext    = is_signed_i ? {a_i[31], a_i[31:0]} : {1'b0, a_i};
  assign b_ext    = is_signed_i ? {b_i[31], b_i[31:0]} : {1'b0, b_i};
  assign a_neg_1x = ~{a_ext[32],a_ext};
  assign a_neg_2x = {~a_ext,1'b0};
  assign a_pos_1x = {a_ext[32],a_ext};
  assign a_pos_2x = {a_ext,1'b0};

  assign a_pp_src[3] = a_neg_2x;
  assign a_pp_src[2] = a_neg_1x;
  assign a_pp_src[1] = a_pos_2x;
  assign a_pp_src[0] = a_pos_1x;

  generate
    for (genvar i = 0; i < PP_NUM; i += 1) begin : gen_booth_pp
      onehot_mux #(
          .T(logic [33:0]),
          .SEL_WIDTH(4)
      ) u_pp_mux (
          .sel_oh_i(pp_sel[i]),
          .data_i  (a_pp_src),
          .data_o  (pp[i])
      );

      booth_radix4 #(
          .WIDTH(33)
      ) u_booth_enc (
          .data_sign_ext_i(b_ext),
          .is_neg_2x_o(pp_sel[i][0]),
          .is_neg_1x_o(pp_sel[i][1]),
          .is_pos_2x_o(pp_sel[i][2]),
          .is_pos_1x_o(pp_sel[i][3]),
          .neg_c_o(neg_c[i])
      );
    end
  endgenerate

  // arrange the partial product
  // refer to Digital Arithmetic(Chapter 4.2.1), Ercegovac.
  assign pp_ext[0] = {30'd0, ~pp[0][33], pp[0][33], pp[0]};
  assign pp_ext[1] = {29'd0, 1'b1, ~pp[1][33], pp[1][32:0], neg_c[0]};
  assign pp_ext[PP_NUM-1] = {2'd0, pp[PP_NUM-1][31:0], neg_c[PP_NUM-2], 30'd0};
  generate
    for (genvar i = 2; i < PP_NUM - 1; i += 1) begin : gen_pp_ext
      assign pp_ext[i] = {
        {(29 - (i - 1) * 2) {1'b0}},
        1'b1,
        ~pp[i][33],
        pp[i][32:0],
        neg_c[i-1],
        {((i - 1) * 2) {1'b0}}
      };
    end
  endgenerate

  // wallace tree



endmodule
