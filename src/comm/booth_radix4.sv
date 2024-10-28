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
  * File Name: booth_radix4.sv
  * Creation Date: 2024/10/20
  * Author: jackkyyang
  * Description:
  *   modified booth's encoder supporting both signed and unsigned number.
  * Parameter List:
  *  - WIDTH: width of the input data.
              must be greater than or equal to 4
  * Input Ports:
  *  - data_sign_ext_i[WIDTH-1:0]:  input data in a signed format
  * Output Ports:
  *  - is_neg_2x_o[WIDTH/2:0]:  the encoding result is -2 * operand
  *  - is_neg_1x_o[WIDTH/2:0]:  the encoding result is -1 * operand
  *  - is_pos_2x_o[WIDTH/2:0]:  the encoding result is 2 * operand
  *  - is_pos_1x_o[WIDTH/2:0]:  the encoding result is 1 * operand
 ***************************************************************************
*/

module booth_radix4
  import alu_comm_pkg::*;
#(
    parameter  integer WIDTH  = 8,
    localparam integer PP_NUM = calc_pp_num(WIDTH)
) (
    input  logic signed [ WIDTH-1:0] data_sign_ext_i,
    output logic        [PP_NUM-1:0] is_neg_2x_o,
    output logic        [PP_NUM-1:0] is_neg_1x_o,
    output logic        [PP_NUM-1:0] is_pos_2x_o,
    output logic        [PP_NUM-1:0] is_pos_1x_o,
    output logic        [       1:0] neg_c_o        [PP_NUM-1:0]
);

  /*
  *************************************************************************************
  * An SIGNED binary number whose width is even can be represented as:
  *   b = -2^(n-1)*b[n-1] + 2^(n-2)*b[n-2] + ... + 2^1*b[1] + 2^0*b[0]
  *   where b[n-1] is the most significant bit, and b[0] is the least significant bit.
  * it can be encoded as:
  *   b = 2^(n-2)*(-2*b[n-1] + b[n-2] + b[n-3]) +
  *       2^(n-4)*(-2*b[n-3] + b[n-4] + b[n-5]) + ... +
  *       2^2*(-2*b[3] + b[2] + b[1]) +
  *       2^0*(-2*b[1] + b[0] + b[-1])
  *   where b[-1] is 0
  *************************************************************************************
  */


  wire [WIDTH:0] data_ext = {data_sign_ext_i[WIDTH-1], data_sign_ext_i};

  // 2'b00:  0
  // 2'b01:  1
  // 2'b10:  -2
  // 2'b11:  -1
  //encoding of last two bits
  assign is_neg_2x_o[0] = data_sign_ext_i[1:0] == 2'b10;
  assign is_neg_1x_o[0] = data_sign_ext_i[1:0] == 2'b11;
  assign is_pos_2x_o[0] = 1'b0;
  assign is_pos_1x_o[0] = data_sign_ext_i[1:0] == 2'b01;

  generate
    for (genvar i = 1; i < PP_NUM; i += 1) begin : gen_enc_loop
      // 3'b000: 0
      // 3'b001: 1
      // 3'b010: 1
      // 3'b011: 2
      // 3'b100: -2
      // 3'b101: -1
      // 3'b110: -1
      // 3'b111: 0
      assign is_neg_2x_o[i] = data_ext[2*i+1] & (~(|data_ext[2*i:2*i-1]));
      assign is_neg_1x_o[i] = data_ext[2*i+1] & (^data_ext[2*i:2*i-1]);
      assign is_pos_2x_o[i] = ~data_ext[2*i+1] & (&data_ext[2*i:2*i-1]);
      assign is_pos_1x_o[i] = ~data_ext[2*i+1] & (^data_ext[2*i:2*i-1]);
    end
  endgenerate

  generate
    for (genvar i = 0; i < PP_NUM; i += i) begin : gen_neg_c
      assign neg_c_o[i] = ({2{is_neg_2x_o[i]}} & 2'b10) | ({2{is_neg_1x_o[i]}} & 2'b01);
    end
  endgenerate

`ifdef COMM_ASSERT
  // SVA assertion to check if sel_oh is one-hot encoded
  initial begin
    #0;
    assert (WIDTH >= 4)
    else $fatal("WIDTH of booth encoder must be greater than or equal to 4");
  end
`endif  // COMM_ASSERT

endmodule
