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
              must be even and greater than or equal to 4
  * Input Ports:
  *  - data_i: input data in a signed or unsigned format
  *  - unsigned_i: 0 for signed, 1 for unsigned
  * Output Ports:
  *  - enc_o: encoded data in radix-4 format
  *            the number of encode result is (WIDTH/2) + 1
  *            [2]: negative
  *            [1]: is zero
  *            [0]: sel data * 1 or data * 2
 ***************************************************************************
*/

module booth_radix4 #(
    parameter integer WIDTH = 8
) (
    input  logic signed [WIDTH-1:0] data_i,
    input  logic                    unsigned_i,            // 0 for signed, 1 for unsigned
    output logic        [      2:0] enc_o     [WIDTH/2:0]  // {neg, zero, data*2 or data*1}
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
  * An UNSIGNED binary number whose width is even can be represented as:
  *   b = 2^(n-1)*b[n-1] + 2^(n-2)*b[n-2] + ... + 2^1*b[1] + 2^0*b[0]
  *   where b[n-1] is the most significant bit, and b[0] is the least significant bit.
  * it can be encoded as:
  *   b = 2^(n)*(-2*b[n+1] + b[n] + b[n-1]) +
  *       2^(n-2)*(-2*b[n-1] + b[n-2] + b[n-3]) +
  *       2^(n-4)*(-2*b[n-3] + b[n-4] + b[n-5]) + ... +
  *       2^2*(-2*b[3] + b[2] + b[1]) +
  *       2^0*(-2*b[1] + b[0] + b[-1])
  *   where b[-1] is 0
  *************************************************************************************
  */


  localparam logic [2:0] ZERO = 3'b010;
  localparam logic [2:0] POS_ONE = 3'b000;
  localparam logic [2:0] POS_DOUBLE = 3'b001;
  localparam logic [2:0] MINUS_ONE = 3'b100;
  localparam logic [2:0] MINUS_DOUBLE = 3'b101;

  //encoding of last two bits
  always_comb begin : booth_lsb
    // {signed, zero, data*1 or data*2}
    case (data_i[1:0])
      2'b00:   enc_o[0] = ZERO;  // 0
      2'b01:   enc_o[0] = POS_ONE;  // 1
      2'b10:   enc_o[0] = MINUS_DOUBLE;  // -2
      2'b11:   enc_o[0] = MINUS_ONE;  // -1
      default: enc_o[0] = 'x;
    endcase
  end

  generate
    for (genvar i = 1; i < WIDTH / 2; i += 1) begin : gen_enc_loop
      always_comb begin : booth_enc
        // {signed, zero, data*1 or data*2}
        case (data_i[2*i+1:2*i-1])
          3'b000:  enc_o[i] = ZERO;  // 0
          3'b001:  enc_o[i] = POS_ONE;  // 1
          3'b010:  enc_o[i] = POS_ONE;  // 1
          3'b011:  enc_o[i] = POS_DOUBLE;  // 2
          3'b100:  enc_o[i] = MINUS_DOUBLE;  // -2
          3'b101:  enc_o[i] = MINUS_ONE;  // -1
          3'b110:  enc_o[i] = MINUS_ONE;  // -1
          3'b111:  enc_o[i] = ZERO;  // 0
          default: enc_o[i] = 'x;
        endcase
      end
    end
  endgenerate

  // the unsigned number need one more enc_o to get the correct result
  assign enc_o[WIDTH/2] = unsigned_i & data_i[WIDTH-1] ? POS_ONE : ZERO;


`ifdef COMM_ASSERT
  // SVA assertion to check if sel_oh is one-hot encoded
  initial begin
    #0;
    assert (WIDTH % 2 == 0)
    else $fatal("WIDTH of input data must be even");

    assert (WIDTH >= 4)
    else $fatal("WIDTH of booth encoder must be greater than or equal to 4");
  end
`endif  // COMM_ASSERT

endmodule
