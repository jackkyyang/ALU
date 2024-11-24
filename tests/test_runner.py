import argparse
import os
import shutil
from pathlib import Path

from cocotb.runner import get_runner


def filelist_parse(filelist_path: Path) -> list[str]:
    filelist = []
    with filelist_path.open() as f:
        for line in f:
            valid_str = line.strip()
            if (
                valid_str == ""
                or valid_str.startswith("#")
                or valid_str.startswith("//")
            ):
                continue
            filelist.append(os.path.expandvars(valid_str))
    return filelist


def module_parse(m_path: Path) -> tuple[list[str], str]:
    if not m_path.is_dir():
        return ([f"ERROR! module_path:{m_path} is not a directory"], "")

    filelist = []
    module_name = m_path.name
    filelist_path = m_path / f"{module_name}.f"
    top_name = f"{module_name}.sv"
    top_path = m_path / top_name

    if not top_path.exists():
        return ([f"ERROR! Cannot find design file:{top_path}"], "")

    if filelist_path.exists():
        filelist = filelist_parse(filelist_path)
    else:
        return ([f"ERROR! Cannot find filelist:{filelist_path}"], "")

    return filelist, module_name


class TestRunner:
    def __init__(self, module_path: str):
        self.exec_path = Path.cwd().resolve()
        self.m_path = Path(module_path).resolve()
        self.test_path = Path(__file__).parent

        self.sources, self.toplevel = module_parse(self.m_path)
        if self.toplevel == "":
            raise ValueError(self.sources[0])

        self.sim_build_path = self.test_path / "build" / self.toplevel

        print("######################################")
        print(f"# Execute Dir: {self.exec_path}")
        print(f"# Test Dir   : {self.test_path}")
        print(f"# Module Dir : {self.m_path}")
        print(f"# Build Dir  : {self.sim_build_path}")
        print("######################################")

        sim = os.getenv("SIM", "verilator")
        self.runner = get_runner(sim)

    def build(self, waves: bool = True) -> None:
        build_args = []
        if waves:
            build_args = [
                "--trace",
                "--trace-fst",
                "--trace-structs",
            ]

        self.runner.build(
            sources=self.sources,
            hdl_toplevel=self.toplevel,
            waves=waves,
            build_args=build_args,
            build_dir=str(self.sim_build_path),
        )

    def run_sim(self, case_name: str, waves: bool = False) -> None:
        test_name = f"test_{case_name}"
        print("######################################")
        print(f"# Test Name  : {test_name}")
        print("######################################")

        test_args = []
        if waves:
            test_args = [
                "--trace",
                "--trace-fst",
                "--trace-structs",
            ]

        self.runner.test(
            test_module=[test_name],
            hdl_toplevel=self.toplevel,
            test_args=test_args,
            build_dir=str(self.sim_build_path),
        )

    def open_wave(self) -> None:
        design_xml = self.sim_build_path / "Vtop.xml"
        stem_file = self.sim_build_path / f"{self.toplevel}.stems"
        wave_file = self.sim_build_path / "dump.fst"

        self.runner.build(
            sources=self.sources,
            hdl_toplevel=self.toplevel,
            build_args=["--xml-only"],
            build_dir=str(self.sim_build_path),
        )

        if not wave_file.exists():
            raise FileNotFoundError(f"Cannot find wave file:{wave_file}")
        if not design_xml.exists():
            raise FileNotFoundError(f"Cannot find design xml file:{design_xml}")

        os.system(f"xml2stems {design_xml} {stem_file}")
        os.system(f"gtkwave {wave_file} -t {stem_file} &")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run tests for the given module path."
    )
    parser.add_argument(
        "module_path", type=str, help="Path to the module to be tested"
    )

    parser.add_argument(
        "--run_case",
        type=str,
        help="Skip the build step, only run the test case",
    )

    parser.add_argument(
        "--wave",
        help="enable wave dump",
        default=False,
        action="store_true",
    )

    parser.add_argument(
        "--open_wave",
        help="open waveform",
        default=False,
        action="store_true",
    )

    parser.add_argument(
        "--clean",
        help="clean the build directory",
        default=False,
        action="store_true",
    )

    args = parser.parse_args()

    test_runner = TestRunner(args.module_path)

    if args.clean:
        print("Cleaning build directory:", test_runner.sim_build_path)
        shutil.rmtree(test_runner.sim_build_path)
        exit(0)

    if args.open_wave:
        test_runner.open_wave()
        exit(0)

    if not args.run_case:
        test_runner.build(args.wave)
    else:
        test_runner.build(args.wave)
        test_runner.run_sim(args.run_case, args.wave)
