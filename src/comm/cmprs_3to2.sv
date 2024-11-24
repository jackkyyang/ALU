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
 * File Name: cmprs_3to2.sv
 * Creation Date: 2024/10/20
 * Author: jackkyyang
 * Description:
 *   a fast 3-to-2 compressor(CSA).
 ***************************************************************************
*/


module cmprs_3to2
#(
  parameter integer WIDTH = 1
)
(
    input  logic [WIDTH-1:0] a,     // input a
    input  logic [WIDTH-1:0] b,     // input b
    input  logic [WIDTH-1:0] c,     // input c
    output logic [WIDTH-1:0] cout,  // carry out
    output logic [WIDTH-1:0] sum    // sum
);

  assign sum  = a ^ b ^ c;
  assign cout = (a & b) | (b & c) | (a & c);

endmodule
