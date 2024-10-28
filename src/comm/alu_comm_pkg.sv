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
  * File Name: alu_comm_pkg.sv
  * Creation Date: 2024/10/27
  * Author: jackkyyang
  * Description:
  *   common functions and types for libs of ALU
 ***************************************************************************
*/

package alu_comm_pkg;

  function automatic integer calc_pp_num(input integer WIDTH);
    if (WIDTH % 2 == 0) return WIDTH / 2;
    else return WIDTH / 2 + 1;

  endfunction

endpackage
