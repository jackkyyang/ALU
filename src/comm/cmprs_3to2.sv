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


module cmprs_3to2 (
    input  logic [2:0] data,  // 3-bit data
    output logic       cout,  // carry out
    output logic       sum    // sum
);

  assign sum  = (^data);
  assign cout = (data[0] & data[1]) | (data[1] & data[2]) | (data[0] & data[2]);

endmodule
