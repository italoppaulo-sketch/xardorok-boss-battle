"""Run the engine's test suites; fail on script errors even when Godot exits zero."""
import argparse
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SUITES = ["test_battle", "test_marco4", "test_abilities", "test_scene", "test_input", "test_encounters", "test_visuals"]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot", help="Godot 4.7.2 executable")
    args = parser.parse_args()
    commands = [["--headless", "--editor", "--quit"]]
    commands += [["--headless", "--script", f"tests/{name}.gd"] for name in SUITES]
    commands.append(["--headless", "--quit-after", "120"])
    failed = False
    for command in commands:
        result = subprocess.run(
            [args.godot, "--path", str(ROOT), *command],
            cwd=ROOT, capture_output=True, text=True, timeout=180, check=False,
        )
        output = result.stdout + result.stderr
        print(output, end="")
        ok = result.returncode == 0 and "ERROR:" not in output
        print(f"{'PASS' if ok else 'FAIL'}: {' '.join(command)}")
        failed |= not ok
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
