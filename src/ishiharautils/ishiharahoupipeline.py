import subprocess
from pathlib import Path
import os
import json
from datetime import datetime

class IshiharaPipeline:
    """
    Pipeline for executing a series of Fortran-based corrections and computations
    starting from a .lsd file. The pipeline includes lsdstat, llfind, llfinddble,
    and lwt steps, and logs all results.
    """
    def __init__(self, input_file: Path, fortran_dir: Path = None):
        self.input_file = input_file
        self.basename = input_file.stem
        self.output_dir = input_file.parent

        # ↓ デフォルトで「このファイルの親 → fortran wrappers」へ
        if fortran_dir is None:
            self.fortran_dir = Path(__file__).parents[1] / "ishihara-fortranwrappers"
        else:
            self.fortran_dir = fortran_dir

        self.lsd_file = self.input_file.with_suffix(".lsd")
        self.stat_file = self.output_dir / f"{self.basename}lsd.stat"
        self.lfind_file = self.output_dir / f"{self.basename}.lfind"
        self.lfind2_file = self.output_dir / f"{self.basename}.lfind2"
        self.lwt_file = self.output_dir / f"{self.basename}.lwt"
        self.lncor_file = self.output_dir / f"{self.basename}.lncor12_35_40"

        self.temp_file = self.output_dir / ".temp"

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.output_dir / f"pipeline_log_{self.basename}_{timestamp}.json"
        self.log_data = {
            "input_file": str(self.input_file),
            "script": "ishihara_pipeline.py",
            "steps": [],
            "outputs": {},
            "timestamp": timestamp
        }

    def fortran(self, name, relative_to_data=False):
        # Resolves the path to the specified Fortran binary.
        path = (Path("..") / self.fortran_dir / name) if relative_to_data else (self.fortran_dir / name)
        resolved = Path(path).resolve()
        if not resolved.exists():
            raise FileNotFoundError(f"Fortran binary not found: {resolved}")
        return str(resolved)


    def log_step(self, step_name, output_file=None):
        # Logs the execution of a processing step and its output.
        entry = {"step": step_name}
        if output_file:
            entry["output"] = str(output_file)
            self.log_data["outputs"][step_name] = str(output_file)
        self.log_data["steps"].append(entry)

    def write_log(self):
        # Writes the pipeline execution log to a JSON file.
        with open(self.log_file, "w") as f:
            json.dump(self.log_data, f, indent=2)
        print(f"📘 Log saved to {self.log_file}")

    def run_lsdstat(self):
        # Runs the 'lsdstat' Fortran program on the .lsd file and writes the output to .stat.
        with open(self.lsd_file, "r") as fin, open(self.stat_file, "w") as fout:
            subprocess.run([self.fortran("lsdstat")], stdin=fin, stdout=fout)
        if self.stat_file.stat().st_size == 0:
            raise RuntimeError(f"{self.stat_file} is empty. lsdstat might have failed.")
        self.log_step("lsdstat", self.stat_file)
        print(f" - {self.stat_file.name} written")

    def run_llfind(self):
        # Runs the 'llfind' Fortran program using the .lsd and .stat files, writes the output to .lfind.
        with open(self.temp_file, "w") as f:
            f.write(f"{self.lsd_file.name}\n")
            f.write(f"{self.stat_file.name}\n")
        with open(self.temp_file, "r") as fin, open(self.lfind_file, "w") as fout:
            subprocess.run(
                [self.fortran("llfind")],
                stdin=fin,
                stdout=fout,
                cwd=self.output_dir
            )
        self.log_step("llfind", self.lfind_file)
        print(f" - {self.lfind_file.name} written")

    def run_llfinddble(self):
        #    Runs 'llfinddble' Fortran program on the .lfind file and sorts the output, saving to .lfind2.
        p1 = subprocess.Popen([self.fortran("llfinddble")], stdin=open(self.lfind_file, "r"), stdout=subprocess.PIPE)
        with open(self.lfind2_file, "w") as fout:
            subprocess.run(["sort", "-n"], stdin=p1.stdout, stdout=fout)
        self.log_step("llfinddble", self.lfind2_file)
        print(f" - {self.lfind2_file.name} written")

    def run_lwt(self):
        self.lwt_file = self.output_dir / f"{self.basename}.lwt"
        with open(self.temp_file, "w") as f:
            f.write(f"{self.lsd_file.name}\n")
            f.write(f"{self.stat_file.name}\n")
            f.write(f"{self.lfind2_file.name}\n")
            f.write(f"{self.lwt_file.name}\n")
        
        with open(self.temp_file, "r") as fin:
            subprocess.run(
                [self.fortran("lwt")],
                stdin=fin,
                cwd=self.output_dir
            )

        self.log_step("lwt", self.lwt_file)
        print(f" - {self.lwt_file.name} written.")

    def cleanup(self):
        # Removes the temporary file used for Fortran input.
        if self.temp_file.exists():
            os.remove(self.temp_file)
            print(f"🧹 Removed temp file: {self.temp_file}")

    def run_from_lsd(self):
        # Runs the full pipeline starting from an existing .lsd file,
        # executing lsdstat, llfind, llfinddble, and lwt in sequence.
        if not self.lsd_file.exists():
            raise FileNotFoundError(f"{self.lsd_file} not found. Please provide an existing .lsd file.")
        self.run_lsdstat()
        self.run_llfind()
        self.run_llfinddble()
        self.run_lwt()
        self.cleanup()
        self.write_log()
