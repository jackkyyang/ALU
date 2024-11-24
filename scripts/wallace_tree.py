# Copyright 2024 jackkyyang.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# **************************************************************************
# File Name: wallace_tree.py
# Creation Date: 2024/10/29
# Author: jackkyyang
# Description:
#   a Wallace Tree multiplier generator for binary numbers.
# **************************************************************************

from pprint import pprint
from typing import Optional

BOOTH_DELAY = 4.0
AND_DELAY = 1.0
OR_DELAY = 1.0
XOR_DELAY = 1.5


class Signal:
    def __init__(self, name: str, depth: float, host: "Optional[Compressor]"):
        self.latency: float = depth
        self.name: str = name
        self.host: Optional[Compressor] = host
        self.loader: Optional[Compressor] = None


TIE_LOW = Signal("1'b0", 0.0, None)


class Compressor:
    def __init__(self, column: int, level: int, no: int, module_name: str):
        self.column: int = column
        self.level: int = level
        self.name: str = f"u_{module_name}_{column}_{level}_{no}"


class Compressor2to1(Compressor):
    module_name = "cmprs_2to1"
    latency_sum = XOR_DELAY  # a ^ b
    latency_cout = AND_DELAY  # a & b

    def __init__(self, a: Signal, b: Signal, column: int, level: int, no: int):
        super().__init__(column, level, no, Compressor2to1.module_name)
        self.input_dict = {"a": a, "b": b}
        max_ab = max(a.latency, b.latency)
        sum_delay = max_ab + Compressor2to1.latency_sum
        cout_delay = max_ab + Compressor2to1.latency_cout
        self.sum: Signal = Signal(self.name + "_sum", sum_delay, self)
        self.cout: Signal = Signal(self.name + "_cout", cout_delay, self)


class Compressor3to2(Compressor):
    module_name = "cmprs_3to2"
    latency_sum = XOR_DELAY * 2  # a ^ b ^ c
    latency_cout = AND_DELAY + OR_DELAY  # a & b | b & c | a & c

    def __init__(
        self, a: Signal, b: Signal, c: Signal, column: int, level: int, no: int
    ):
        super().__init__(column, level, no, Compressor3to2.module_name)
        self.input_dict = {"a": a, "b": b, "c": c}
        max_abc = max(a.latency, b.latency, c.latency)
        sum_delay = max_abc + Compressor3to2.latency_sum
        cout_delay = max_abc + Compressor3to2.latency_cout
        self.sum: Signal = Signal(self.name + "_sum", sum_delay, self)
        self.cout: Signal = Signal(self.name + "_cout", cout_delay, self)


class Compressor4to2(Compressor):
    module_name = "cmprs_4to2"
    latency_sum = XOR_DELAY * 3  # a ^ b ^ c ^ d ^ cin
    latency_abcd = XOR_DELAY * 2  # xor_abcd
    latency_cin = AND_DELAY  # (xor_abcd & cin)
    latency_cout_a = OR_DELAY  # (xor_abcd & cin) | ((~xor_abcd) & d)
    latency_cout_b = AND_DELAY + OR_DELAY  # (a & b) | (b & c) | (a & c)

    def __init__(
        self,
        a: Signal,
        b: Signal,
        c: Signal,
        d: Signal,
        cin: Signal,
        column: int,
        level: int,
        no: int,
    ):
        super().__init__(column, level, no, Compressor4to2.module_name)
        self.input_dict = {"a": a, "b": b, "c": c, "d": d, "cin": cin}

        max_abc = max(a.latency, b.latency, c.latency)
        max_all = max(max_abc, d.latency, cin.latency)

        abcd_xor = max(max_abc, d.latency) + Compressor4to2.latency_abcd
        cin_and = cin.latency + Compressor4to2.latency_cin
        # a ^ b ^ c ^ d ^ cin
        sum_delay = max_all + Compressor4to2.latency_sum
        # (xor_abcd & cin) | ((~xor_abcd) & d)
        cout_a_delay = max(abcd_xor, cin_and) + Compressor4to2.latency_cout_a
        # (a & b) | (b & c) | (a & c)
        cout_b_delay = max_abc + Compressor4to2.latency_cout_b
        self.sum: Signal = Signal(self.name + "_sum", sum_delay, self)
        self.cout_a: Signal = Signal(self.name + "_cout_a", cout_a_delay, self)
        self.cout_b: Signal = Signal(self.name + "_cout_b", cout_b_delay, self)


class WallaceTree:
    """A class to represent a Wallace Tree for multiplying binary numbers,
    assume that the multiplier was encoded in modified booth's algorithm.
    """

    def __init__(self, width: int, pp_name: str = "pp", logic_depth: int = 20):
        """Initialize the Wallace Tree multiplier generator.

        Args:
            width (int): The width of the original data(NOT signed extended).
                         Must >= 4.
            pp_name (str):
                The name of the partial product signals.
            logic_depth (int):
                The maximum depth of the tree logic in a pipeline.

        Raises:
            ValueError: logic_depth must be at least 3.
            ValueError: if the width is less than 4.

        """
        if width < 4:
            raise ValueError("Width of the Wallace Tree must be at least 4.")
        if logic_depth < 3:
            raise ValueError("depth of the logic must be at least 3.")

        self.width = width
        self.result_width = 2 * width
        # the number of partial products by booth encoding
        self.pp_num = self.width // 2 + 1
        self.tree_map = self.get_wallace_map()
        self.columns: list[list[Signal]] = []
        for i in range(0, self.result_width):
            self.columns.append(self.gen_column(i))

        self.compressors = []

    def get_pp_width(self, row: int) -> int:
        """Calculate the width of the partial product signals in a row.

        Args:
            row (int): The row number.

        Returns:
            list[int]: The width of the partial product signals in the row.

        """
        """
        Example:
                             x x x x
                             ........
                    ~s s s e x x x x
                  1 ~s e x x x x t t
                  s  x x x x t t
    ------------------------------------
                        x x x x x x
                        ............
               ~s s s e x x x x x x
              1 s e x x x x x x t t
          1 s e x x x x x x t t
          s x x x x x x t t
        """

        if row < 0 or row >= self.pp_num:
            raise ValueError(
                f"Row number({row}) out of range:[{self.pp_num-1}:0]."
            )

        if row == 0:
            # booth encoder: add 2 bits to msb
            # sign extension: 2 bits to msb
            pp_width = self.width + 4
        elif row == self.pp_num - 1:
            # booth encoder: add 1 bits to msb
            # neg_cin : 2 bits to lsb
            pp_width = self.width + 3
        else:
            # booth encoder: add 2 bits to msb
            # sign extension: 1 bits to msb
            # neg_cin : 2 bits to lsb
            pp_width = self.width + 5
        return pp_width

    def gen_column(self, column: int) -> list[Signal]:
        column_list = []
        for i in range(0, self.pp_num):
            if self.tree_map[i][column] == 1:
                column_list.append(
                    Signal(f"pp_ext[{i}][{column}]", BOOTH_DELAY, None)
                )
        return column_list

    def get_column_num(self, column: int) -> int:
        """Calculate the number of columns in the Wallace Tree
        for a booth's encoded multiplier


        Args:
            column (int): The column number.

        Returns:
            int: The number of rows in the column.

        """
        if column < 0 or column > self.result_width:
            raise ValueError(
                f"Column number({column}) out of "
                f"range:[{self.result_width-1}:0]."
            )

        return len(self.columns[column])

    def get_wallace_map(self) -> list[list[int]]:
        list_len = self.result_width + 2
        map_list = []
        for i in range(0, self.pp_num, 1):
            if i <= 1:
                start_pos = 0
            else:
                start_pos = i * 2 - 2
            tmp_list = []
            for j in range(0, list_len):
                if j < start_pos or (j >= start_pos + self.get_pp_width(i)):
                    tmp_list.append(0)
                else:
                    tmp_list.append(1)
            map_list.append(tmp_list)
        return map_list

    def generate_tree(self):
        pass

    def print_tree(self):
        pprint(self.tree_map, indent=4)

    def column_add(
        self, col_list: list[Signal], column: int, level: int, no: int
    ) -> tuple[list[Signal], list[Signal]]:
        """Add a column of partial products to the Wallace Tree.

        Return the list of carry-out signal and the sum signal.
        """
        assert len(col_list) > 0
        if len(col_list) == 1:
            col_list.clear()
            return ([], [col_list[0]])
        elif len(col_list) == 2:
            tmp_compressor = Compressor2to1(
                col_list[0], col_list[1], column, level, no
            )
            self.compressors.append(tmp_compressor)
            col_list.clear()
            return ([tmp_compressor.cout], [tmp_compressor.sum])
        elif len(col_list) == 3:
            tmp_compressor = Compressor3to2(
                col_list[0], col_list[1], col_list[2], column, level, no
            )
            self.compressors.append(tmp_compressor)
            col_list.clear()
            return ([tmp_compressor.cout], [tmp_compressor.sum])
        elif len(col_list) == 4:
            tmp_compressor = Compressor4to2(
                col_list[0],
                col_list[1],
                col_list[2],
                col_list[3],
                TIE_LOW,
                column,
                level,
                no,
            )
            self.compressors.append(tmp_compressor)
            col_list.clear()
            return (
                [tmp_compressor.cout_a, tmp_compressor.cout_b],
                [tmp_compressor.sum],
            )
        elif len(col_list) == 5:
            tmp_compressor = Compressor4to2(
                col_list[0],
                col_list[1],
                col_list[2],
                col_list[3],
                col_list[4],
                column,
                level,
                no,
            )
            self.compressors.append(tmp_compressor)
            col_list.clear()
            return (
                [tmp_compressor.cout_a, tmp_compressor.cout_b],
                [tmp_compressor.sum],
            )
        else:
            tmp_compressor = Compressor4to2(
                col_list[-1],
                col_list[-2],
                col_list[-3],
                col_list[-4],
                col_list[-5],
                column,
                level,
                no,
            )
            self.compressors.append(tmp_compressor)
            for _ in range(0, 5):
                col_list.pop()
            tmp_cout = [tmp_compressor.cout_a, tmp_compressor.cout_b]
            tmp_sum = [tmp_compressor.sum]
            cout_remain, sum_remain = self.column_add(
                col_list, column, level, no + 1
            )
            tmp_cout.extend(cout_remain)
            tmp_sum.extend(sum_remain)
            return (tmp_cout, tmp_sum)

    def tree_reduce(self, columns: list[list[Signal]], level: int):
        if max(map(lambda x: len(x), columns)) <= 2:
            for col in columns:
                for sig in col:
                    print(sig.name)
        else:
            carry_list = []
            sum_list = []
            for i, col in enumerate(columns):
                carry, sum_o = self.column_add(col, i, level, 0)
                carry_list.append(carry)
                sum_list.append(sum_o)
            self.tree_reduce()
            # print(carry_list)
            # print(sum_list)


if __name__ == "__main__":
    tree = WallaceTree(8)
    tree.print_tree()
    print(tree.get_column_num(0))
    print(tree.get_column_num(1))
    print(tree.get_column_num(2))
    print(tree.get_column_num(3))
    print(tree.get_column_num(4))
    print(tree.get_column_num(5))
    print(tree.get_column_num(6))
    print(tree.get_column_num(7))
    # print(tree.get_column_num(8))
    # print(tree.get_column_num(9))
    # print(tree.get_column_num(10))
    # print(tree.get_column_num(11))
    # print(tree.get_column_num(12))
