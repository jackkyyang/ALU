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
 * File Name: cmprs_2to1.sv
 * Creation Date: 2024/10/20
 * Author: jackkyyang
 * Description:
 *   a 2-to-1 compressor(Half Adder).
 ***************************************************************************
*/


module cmprs_2to1 (
    input  logic a,     // input a
    input  logic b,     // input b
    output logic cout,  // carry out
    output logic sum    // sum
);

  assign sum  = a ^ b;
  assign cout = a & b;

endmodule
