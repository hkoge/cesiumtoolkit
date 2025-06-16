import sys
import os
import re

def parse_size(size_str):
    """Convert human-readable size strings (e.g., '10MB', '5.5MiB') to bytes."""
    units = {
        "b": 1,
        "kb": 10**3, "mb": 10**6, "gb": 10**9,
        "kib": 2**10, "mib": 2**20, "gib": 2**30,
    }

    match = re.fullmatch(r"(?i)(\d+(?:\.\d+)?)([kmgt]?i?b)?", size_str.strip())
    if not match:
        raise ValueError(f"Invalid size format: '{size_str}'")

    number, unit = match.groups()
    number = float(number)
    unit = (unit or "b").lower()

    if unit not in units:
        raise ValueError(f"Unknown unit: '{unit}'")

    return int(number * units[unit])

def trim_file_to_size(input_path, output_path, max_size_bytes):
    current_size = 0
    output_lines = []

    with open(input_path, 'r', encoding='utf-8') as f:
        for line in f:
            line_size = len(line.encode('utf-8'))
            if current_size + line_size > max_size_bytes:
                break
            output_lines.append(line)
            current_size += line_size

    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)

    print(f"Done. Trimmed to {current_size:,} bytes and written to '{output_path}'.")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python trim_to_size.py input.txt output.txt [max_size (e.g., 20MB)]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    size_str = sys.argv[3] if len(sys.argv) > 3 else "20MB"

    if not os.path.exists(input_file):
        print(f"Error: file not found: {input_file}")
        sys.exit(1)

    try:
        max_bytes = parse_size(size_str)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    trim_file_to_size(input_file, output_file, max_bytes)
