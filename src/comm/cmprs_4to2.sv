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
 * File Name: cmprs_4to2.sv
 * Creation Date: 2024/10/20
 * Author: jackkyyang
 * Description:
 *   a fast 4-to-2 compressor.
 ***************************************************************************
*/

module cmprs_4to2 (
    input  logic       cin,   // carry in
    input  logic [3:0] data,  // 4-bit data
    output logic [1:0] cout,  // carry out
    output logic       sum    // sum
);

  wire a = data[0];
  wire b = data[1];
  wire c = data[2];
  wire d = data[3];

  wire xor_ab = a ^ b;
  wire xor_cd = c ^ d;

  wire xor_abcd = (xor_ab ^ xor_cd);

  assign sum = xor_abcd ^ cin;
  assign cout[0] = (xor_abcd & cin) | ((~xor_abcd) & d);
  assign cout[1] = (a & b) | (b & c) | (a & c);


endmodule
