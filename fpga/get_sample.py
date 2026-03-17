#!/usr/bin/env python3
import serial
import sys

def read_serial(device, baudrate, num_lines=100, output_file=None):
    """Read num_lines from serial device and write to file or stdout"""
    try:
        ser = serial.Serial(device, baudrate, timeout=1)
        
        if output_file:
            output_handle = open(output_file, 'w')
            print(f"Reading from {device} at {baudrate} baud...", file=sys.stderr)
            print(f"Output will be saved to {output_file}", file=sys.stderr)
        else:
            output_handle = sys.stdout
            print(f"Reading from {device} at {baudrate} baud...", file=sys.stderr)
        
        lines_read = 0
        
        try:
            while lines_read < num_lines:
                line = ser.readline().decode('utf-8', errors='ignore')
                if line:
                    output_handle.write(line)
                    lines_read += 1
                    if output_file:
                        print(f"[{lines_read}/{num_lines}] {line.rstrip()}", file=sys.stderr)
                else:
                    # No data received
                    pass
        finally:
            if output_file:
                output_handle.close()
        
        ser.close()
        if output_file:
            print(f"\nSuccessfully read {lines_read} lines to {output_file}", file=sys.stderr)
        else:
            print(f"\nSuccessfully read {lines_read} lines", file=sys.stderr)
        
    except FileNotFoundError:
        print(f"Error: Serial device {device} not found")
        sys.exit(1)
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        ser.close()
        sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 read_serial.py <device> [baudrate] [num_lines] [output_file]", file=sys.stderr)
        print("Example: python3 read_serial.py /dev/ttyACM0 9600 100 output.txt", file=sys.stderr)
        print("If output_file is not specified, output goes to stdout", file=sys.stderr)
        sys.exit(1)
    
    device = sys.argv[1]
    baudrate = int(sys.argv[2]) if len(sys.argv) > 2 else 9600
    num_lines = int(sys.argv[3]) if len(sys.argv) > 3 else 100
    output_file = sys.argv[4] if len(sys.argv) > 4 else None
    
    read_serial(device, baudrate, num_lines, output_file)
