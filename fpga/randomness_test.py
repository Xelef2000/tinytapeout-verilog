#!/usr/bin/env python3
"""
Randomness Test Suite for Hardware RNG
Fetches samples from serial device and performs comprehensive statistical tests.
"""

import serial
import sys
import re
import math
import argparse
from collections import Counter
from typing import List, Tuple, Optional

# Try to import scipy for advanced tests, but make it optional
try:
    from scipy import stats
    from scipy.fft import fft
    import numpy as np
    SCIPY_AVAILABLE = True
except ImportError:
    SCIPY_AVAILABLE = False


class RandomnessTests:
    """Collection of randomness tests for binary data."""

    def __init__(self, data: bytes):
        self.data = data
        self.bits = self._bytes_to_bits(data)
        self.n = len(self.bits)

    def _bytes_to_bits(self, data: bytes) -> List[int]:
        """Convert bytes to list of bits."""
        bits = []
        for byte in data:
            for i in range(7, -1, -1):
                bits.append((byte >> i) & 1)
        return bits

    def frequency_monobit_test(self) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Frequency (Monobit) Test.
        Tests if the number of 1s and 0s are approximately equal.
        """
        ones = sum(self.bits)
        zeros = self.n - ones
        s = abs(ones - zeros) / math.sqrt(self.n)
        p_value = math.erfc(s / math.sqrt(2))
        passed = p_value >= 0.01

        ratio = ones / self.n if self.n > 0 else 0
        detail = f"Ones: {ones} ({ratio:.4f}), Zeros: {zeros} ({1-ratio:.4f}), S={s:.4f}"
        return passed, p_value, detail

    def frequency_block_test(self, block_size: int = 128) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Frequency Test within a Block.
        Tests proportion of 1s within M-bit blocks.
        """
        n_blocks = self.n // block_size
        if n_blocks == 0:
            return False, 0.0, "Insufficient data for block test"

        chi_sq = 0
        for i in range(n_blocks):
            block = self.bits[i * block_size:(i + 1) * block_size]
            pi = sum(block) / block_size
            chi_sq += (pi - 0.5) ** 2

        chi_sq *= 4 * block_size
        p_value = 1 - self._incomplete_gamma(n_blocks / 2, chi_sq / 2)
        passed = p_value >= 0.01

        detail = f"Blocks: {n_blocks}, Block size: {block_size}, Chi-sq: {chi_sq:.4f}"
        return passed, p_value, detail

    def runs_test(self) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Runs Test.
        Tests the total number of runs (uninterrupted sequences of identical bits).
        """
        ones = sum(self.bits)
        pi = ones / self.n

        # Pre-test: check if monobit passes
        if abs(pi - 0.5) >= 2 / math.sqrt(self.n):
            return False, 0.0, "Pre-test failed (monobit)"

        # Count runs
        runs = 1
        for i in range(1, self.n):
            if self.bits[i] != self.bits[i - 1]:
                runs += 1

        expected = 2 * self.n * pi * (1 - pi) + 1
        std = 2 * math.sqrt(2 * self.n) * pi * (1 - pi)

        if std == 0:
            return False, 0.0, "Standard deviation is zero"

        z = (runs - expected) / std
        p_value = math.erfc(abs(z) / math.sqrt(2))
        passed = p_value >= 0.01

        detail = f"Runs: {runs}, Expected: {expected:.2f}, Z: {z:.4f}"
        return passed, p_value, detail

    def longest_run_of_ones_test(self) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Longest Run of Ones in a Block Test.
        """
        # Determine parameters based on data size
        if self.n < 128:
            return False, 0.0, "Insufficient data (need at least 128 bits)"
        elif self.n < 6272:
            M, K = 8, 3
            v = [1, 2, 3, 4]
            pi = [0.2148, 0.3672, 0.2305, 0.1875]
        elif self.n < 750000:
            M, K = 128, 5
            v = [4, 5, 6, 7, 8, 9]
            pi = [0.1174, 0.2430, 0.2493, 0.1752, 0.1027, 0.1124]
        else:
            M, K = 10000, 6
            v = [10, 11, 12, 13, 14, 15, 16]
            pi = [0.0882, 0.2092, 0.2483, 0.1933, 0.1208, 0.0675, 0.0727]

        n_blocks = self.n // M
        freq = [0] * len(v)

        for i in range(n_blocks):
            block = self.bits[i * M:(i + 1) * M]
            max_run = 0
            current_run = 0
            for bit in block:
                if bit == 1:
                    current_run += 1
                    max_run = max(max_run, current_run)
                else:
                    current_run = 0

            # Categorize
            if max_run <= v[0]:
                freq[0] += 1
            elif max_run >= v[-1]:
                freq[-1] += 1
            else:
                for j in range(len(v) - 1):
                    if max_run == v[j + 1]:
                        freq[j + 1] += 1
                        break

        chi_sq = sum((freq[i] - n_blocks * pi[i]) ** 2 / (n_blocks * pi[i])
                     for i in range(len(v)) if n_blocks * pi[i] > 0)

        p_value = 1 - self._incomplete_gamma(K / 2, chi_sq / 2)
        passed = p_value >= 0.01

        detail = f"Blocks: {n_blocks}, Chi-sq: {chi_sq:.4f}"
        return passed, p_value, detail

    def binary_matrix_rank_test(self, M: int = 32, Q: int = 32) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Binary Matrix Rank Test.
        """
        n_matrices = self.n // (M * Q)
        if n_matrices < 38:
            return False, 0.0, f"Insufficient data (need {38 * M * Q} bits, have {self.n})"

        # Simplified rank test - just count full rank matrices
        # Full implementation requires Gaussian elimination
        full_rank = 0
        rank_m1 = 0

        for i in range(n_matrices):
            start = i * M * Q
            matrix_bits = self.bits[start:start + M * Q]
            # Create matrix
            matrix = []
            for row in range(M):
                matrix.append(matrix_bits[row * Q:(row + 1) * Q])

            rank = self._matrix_rank(matrix)
            if rank == min(M, Q):
                full_rank += 1
            elif rank == min(M, Q) - 1:
                rank_m1 += 1

        # Expected probabilities for 32x32 matrix
        p_full = 0.2888
        p_m1 = 0.5776
        p_other = 0.1336

        other = n_matrices - full_rank - rank_m1

        chi_sq = ((full_rank - n_matrices * p_full) ** 2 / (n_matrices * p_full) +
                  (rank_m1 - n_matrices * p_m1) ** 2 / (n_matrices * p_m1) +
                  (other - n_matrices * p_other) ** 2 / (n_matrices * p_other))

        p_value = math.exp(-chi_sq / 2)
        passed = p_value >= 0.01

        detail = f"Matrices: {n_matrices}, Full rank: {full_rank}, Rank-1: {rank_m1}"
        return passed, p_value, detail

    def _matrix_rank(self, matrix: List[List[int]]) -> int:
        """Calculate rank of binary matrix using Gaussian elimination."""
        M = len(matrix)
        Q = len(matrix[0]) if M > 0 else 0
        mat = [row[:] for row in matrix]  # Copy

        rank = 0
        for col in range(min(M, Q)):
            # Find pivot
            pivot_row = None
            for row in range(rank, M):
                if mat[row][col] == 1:
                    pivot_row = row
                    break

            if pivot_row is None:
                continue

            # Swap rows
            mat[rank], mat[pivot_row] = mat[pivot_row], mat[rank]

            # Eliminate
            for row in range(M):
                if row != rank and mat[row][col] == 1:
                    mat[row] = [mat[row][i] ^ mat[rank][i] for i in range(Q)]

            rank += 1

        return rank

    def serial_test(self, m: int = 2) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Serial Test.
        Tests the frequency of all possible m-bit patterns.
        """
        if self.n < m:
            return False, 0.0, "Insufficient data"

        def count_patterns(bits, pattern_len):
            counts = Counter()
            extended = bits + bits[:pattern_len - 1]  # Wrap around
            for i in range(len(bits)):
                pattern = tuple(extended[i:i + pattern_len])
                counts[pattern] += 1
            return counts

        def psi_sq(counts, n, m):
            total = sum(v ** 2 for v in counts.values())
            return (2 ** m / n) * total - n

        psi_m = psi_sq(count_patterns(self.bits, m), self.n, m)
        psi_m1 = psi_sq(count_patterns(self.bits, m - 1), self.n, m - 1) if m > 1 else 0
        psi_m2 = psi_sq(count_patterns(self.bits, m - 2), self.n, m - 2) if m > 2 else 0

        delta_psi = psi_m - psi_m1
        delta2_psi = psi_m - 2 * psi_m1 + psi_m2

        p_value1 = 1 - self._incomplete_gamma(2 ** (m - 2), delta_psi / 2)
        p_value2 = 1 - self._incomplete_gamma(2 ** (m - 3), delta2_psi / 2) if m > 2 else 1.0

        passed = p_value1 >= 0.01 and p_value2 >= 0.01
        detail = f"m={m}, ΔΨ={delta_psi:.4f}, Δ²Ψ={delta2_psi:.4f}"
        return passed, min(p_value1, p_value2), detail

    def approximate_entropy_test(self, m: int = 10) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Approximate Entropy Test.
        """
        if self.n < m + 5:
            return False, 0.0, "Insufficient data"

        def phi(bits, block_len):
            extended = bits + bits[:block_len - 1]
            counts = Counter()
            for i in range(len(bits)):
                pattern = tuple(extended[i:i + block_len])
                counts[pattern] += 1

            c = {k: v / len(bits) for k, v in counts.items()}
            return sum(p * math.log(p) for p in c.values() if p > 0)

        phi_m = phi(self.bits, m)
        phi_m1 = phi(self.bits, m + 1)

        apen = phi_m - phi_m1
        chi_sq = 2 * self.n * (math.log(2) - apen)

        p_value = 1 - self._incomplete_gamma(2 ** (m - 1), chi_sq / 2)
        passed = p_value >= 0.01

        detail = f"m={m}, ApEn={apen:.6f}, Chi-sq={chi_sq:.4f}"
        return passed, p_value, detail

    def cumulative_sums_test(self) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Cumulative Sums (Cusum) Test.
        """
        # Convert to +1/-1
        x = [2 * b - 1 for b in self.bits]

        # Forward cumsum
        s = [0]
        for xi in x:
            s.append(s[-1] + xi)

        z_forward = max(abs(si) for si in s)

        # Backward cumsum
        s = [0]
        for xi in reversed(x):
            s.append(s[-1] + xi)

        z_backward = max(abs(si) for si in s)

        # Calculate p-values
        def cusum_pvalue(z, n):
            total = 0
            start = int((-n / z + 1) / 4)
            end = int((n / z - 1) / 4) + 1
            for k in range(start, end):
                total += (self._normal_cdf((4 * k + 1) * z / math.sqrt(n)) -
                         self._normal_cdf((4 * k - 1) * z / math.sqrt(n)))
            start = int((-n / z - 3) / 4)
            end = int((n / z - 1) / 4) + 1
            for k in range(start, end):
                total -= (self._normal_cdf((4 * k + 3) * z / math.sqrt(n)) -
                         self._normal_cdf((4 * k + 1) * z / math.sqrt(n)))
            return 1 - total

        p_forward = cusum_pvalue(z_forward, self.n)
        p_backward = cusum_pvalue(z_backward, self.n)

        passed = p_forward >= 0.01 and p_backward >= 0.01
        detail = f"Z_fwd={z_forward}, Z_bwd={z_backward}"
        return passed, min(p_forward, p_backward), detail

    def byte_distribution_test(self) -> Tuple[bool, float, str]:
        """
        Chi-square test for uniform byte distribution.
        """
        n_bytes = len(self.data)
        if n_bytes < 256:
            return False, 0.0, "Insufficient data (need at least 256 bytes)"

        observed = Counter(self.data)
        expected = n_bytes / 256

        chi_sq = sum((observed.get(i, 0) - expected) ** 2 / expected for i in range(256))

        # Degrees of freedom = 255
        p_value = 1 - self._incomplete_gamma(255 / 2, chi_sq / 2)
        passed = p_value >= 0.01

        # Find most/least common bytes
        most_common = observed.most_common(3)
        least_common = [(k, observed.get(k, 0)) for k in range(256) if observed.get(k, 0) == min(observed.values())][:3]

        detail = f"Chi-sq={chi_sq:.2f}, Expected/byte={expected:.2f}"
        return passed, p_value, detail

    def autocorrelation_test(self, lag: int = 1) -> Tuple[bool, float, str]:
        """
        Autocorrelation test - checks correlation between bits at distance 'lag'.
        """
        if self.n <= lag:
            return False, 0.0, "Insufficient data"

        # Count XOR sum
        d = lag
        a = sum(self.bits[i] ^ self.bits[i + d] for i in range(self.n - d))

        # Under null hypothesis, expected = (n-d)/2
        expected = (self.n - d) / 2
        std = math.sqrt(self.n - d) / 2

        z = (a - expected) / std
        p_value = math.erfc(abs(z) / math.sqrt(2))
        passed = p_value >= 0.01

        correlation = 1 - 2 * a / (self.n - d)
        detail = f"Lag={lag}, Correlation={correlation:.6f}, Z={z:.4f}"
        return passed, p_value, detail

    def entropy_per_byte(self) -> Tuple[float, str]:
        """
        Calculate Shannon entropy per byte.
        """
        n_bytes = len(self.data)
        if n_bytes == 0:
            return 0.0, "No data"

        counts = Counter(self.data)
        entropy = 0
        for count in counts.values():
            p = count / n_bytes
            if p > 0:
                entropy -= p * math.log2(p)

        detail = f"Entropy: {entropy:.4f} bits/byte (max=8.0), Unique bytes: {len(counts)}/256"
        return entropy, detail

    def spectral_test(self) -> Tuple[bool, float, str]:
        """
        NIST SP 800-22 Discrete Fourier Transform (Spectral) Test.
        Requires scipy/numpy.
        """
        if not SCIPY_AVAILABLE:
            return False, 0.0, "scipy/numpy not available"

        # Convert to +1/-1
        x = np.array([2 * b - 1 for b in self.bits])

        # Compute DFT
        S = np.abs(fft(x))[:self.n // 2]

        # Threshold
        T = math.sqrt(math.log(1 / 0.05) * self.n)
        N0 = 0.95 * self.n / 2
        N1 = np.sum(S < T)

        d = (N1 - N0) / math.sqrt(self.n * 0.95 * 0.05 / 4)
        p_value = math.erfc(abs(d) / math.sqrt(2))
        passed = p_value >= 0.01

        detail = f"Peaks below threshold: {N1}/{self.n // 2}, Expected: {N0:.0f}"
        return passed, p_value, detail

    def _incomplete_gamma(self, a: float, x: float) -> float:
        """Lower incomplete gamma function P(a, x) using series expansion."""
        if x < 0 or a <= 0:
            return 0.0
        if x == 0:
            return 0.0

        # Use continued fraction for large x
        if x > a + 1:
            return 1 - self._incomplete_gamma_cf(a, x)

        # Series expansion
        term = 1 / a
        total = term
        for n in range(1, 200):
            term *= x / (a + n)
            total += term
            if abs(term) < 1e-10:
                break

        return total * math.exp(-x + a * math.log(x) - math.lgamma(a))

    def _incomplete_gamma_cf(self, a: float, x: float) -> float:
        """Upper incomplete gamma using continued fraction."""
        b = x + 1 - a
        c = 1e30
        d = 1 / b
        h = d

        for i in range(1, 200):
            an = -i * (i - a)
            b += 2
            d = an * d + b
            if abs(d) < 1e-30:
                d = 1e-30
            c = b + an / c
            if abs(c) < 1e-30:
                c = 1e-30
            d = 1 / d
            delta = d * c
            h *= delta
            if abs(delta - 1) < 1e-10:
                break

        return h * math.exp(-x + a * math.log(x) - math.lgamma(a))

    def _normal_cdf(self, x: float) -> float:
        """Standard normal CDF."""
        return 0.5 * (1 + math.erf(x / math.sqrt(2)))


def read_samples(device: str, baudrate: int, num_lines: int, verbose: bool = True) -> bytes:
    """Read hex samples from serial device and convert to bytes."""
    try:
        ser = serial.Serial(device, baudrate, timeout=2)
        if verbose:
            print(f"Reading from {device} at {baudrate} baud...", file=sys.stderr)

        data = bytearray()
        lines_read = 0
        errors = 0

        while lines_read < num_lines:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            if not line:
                continue

            # Filter out overflow messages and extract clean hex
            # Handle lines like "DF696F6<iCELink:Overflow>"
            if '<' in line or '>' in line:
                errors += 1
                if verbose:
                    print(f"[SKIP] Overflow detected: {line}", file=sys.stderr)
                continue

            # Validate hex string (should be 8 hex chars for 32-bit value)
            clean = re.sub(r'[^0-9A-Fa-f]', '', line)
            if len(clean) != 8:
                errors += 1
                if verbose and len(clean) > 0:
                    print(f"[SKIP] Invalid length ({len(clean)}): {line}", file=sys.stderr)
                continue

            try:
                value = int(clean, 16)
                # Add 4 bytes (32-bit value, big-endian)
                data.extend(value.to_bytes(4, 'big'))
                lines_read += 1
                if verbose and lines_read % 100 == 0:
                    print(f"[{lines_read}/{num_lines}] samples collected", file=sys.stderr)
            except ValueError:
                errors += 1
                if verbose:
                    print(f"[SKIP] Parse error: {line}", file=sys.stderr)

        ser.close()
        if verbose:
            print(f"\nCollected {lines_read} samples ({len(data)} bytes), {errors} errors skipped", file=sys.stderr)

        return bytes(data)

    except FileNotFoundError:
        print(f"Error: Serial device {device} not found", file=sys.stderr)
        sys.exit(1)
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted by user", file=sys.stderr)
        sys.exit(0)


def read_from_file(filepath: str) -> bytes:
    """Read hex samples from a file."""
    data = bytearray()
    errors = 0
    lines_read = 0

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # Filter out overflow messages
            if '<' in line or '>' in line:
                errors += 1
                continue

            clean = re.sub(r'[^0-9A-Fa-f]', '', line)
            if len(clean) != 8:
                errors += 1
                continue

            try:
                value = int(clean, 16)
                data.extend(value.to_bytes(4, 'big'))
                lines_read += 1
            except ValueError:
                errors += 1

    print(f"Read {lines_read} samples ({len(data)} bytes) from {filepath}, {errors} errors skipped", file=sys.stderr)
    return bytes(data)


def run_all_tests(data: bytes, verbose: bool = True) -> dict:
    """Run all randomness tests and return results."""
    tests = RandomnessTests(data)
    results = {}

    print("\n" + "=" * 70)
    print(f"RANDOMNESS TEST RESULTS - {len(data)} bytes ({len(data) * 8} bits)")
    print("=" * 70)

    # List of tests to run
    test_list = [
        ("Frequency (Monobit)", tests.frequency_monobit_test),
        ("Frequency Block (M=128)", lambda: tests.frequency_block_test(128)),
        ("Runs", tests.runs_test),
        ("Longest Run of Ones", tests.longest_run_of_ones_test),
        ("Binary Matrix Rank", tests.binary_matrix_rank_test),
        ("Serial (m=2)", lambda: tests.serial_test(2)),
        ("Approximate Entropy (m=10)", lambda: tests.approximate_entropy_test(10)),
        ("Cumulative Sums", tests.cumulative_sums_test),
        ("Byte Distribution (Chi-sq)", tests.byte_distribution_test),
        ("Autocorrelation (lag=1)", lambda: tests.autocorrelation_test(1)),
        ("Autocorrelation (lag=8)", lambda: tests.autocorrelation_test(8)),
        ("Autocorrelation (lag=16)", lambda: tests.autocorrelation_test(16)),
        ("Spectral (DFT)", tests.spectral_test),
    ]

    passed_count = 0
    total_count = 0

    print("\n{:<35} {:>8} {:>10}   {}".format("Test", "Result", "P-value", "Details"))
    print("-" * 70)

    for name, test_func in test_list:
        try:
            passed, p_value, detail = test_func()
            results[name] = {"passed": passed, "p_value": p_value, "detail": detail}

            status = "PASS" if passed else "FAIL"
            color = "\033[92m" if passed else "\033[91m"
            reset = "\033[0m"

            if passed:
                passed_count += 1
            total_count += 1

            if verbose:
                print(f"{name:<35} {color}{status:>8}{reset} {p_value:>10.6f}   {detail}")
            else:
                print(f"{name:<35} {status:>8} {p_value:>10.6f}")

        except Exception as e:
            results[name] = {"passed": False, "p_value": 0, "detail": str(e)}
            print(f"{name:<35} {'ERROR':>8} {'N/A':>10}   {str(e)}")

    # Entropy (not a pass/fail test)
    print("-" * 70)
    entropy, entropy_detail = tests.entropy_per_byte()
    results["Entropy"] = {"value": entropy, "detail": entropy_detail}
    print(f"{'Shannon Entropy':<35} {entropy:>8.4f} {'bits/byte':>10}   {entropy_detail}")

    # Summary
    print("\n" + "=" * 70)
    print(f"SUMMARY: {passed_count}/{total_count} tests passed")

    if entropy < 7.0:
        print(f"\033[93mWARNING: Low entropy ({entropy:.4f} bits/byte). Expected ~8.0 for good RNG.\033[0m")
    elif entropy >= 7.9:
        print(f"\033[92mEntropy is excellent ({entropy:.4f} bits/byte).\033[0m")
    else:
        print(f"\033[93mEntropy is acceptable ({entropy:.4f} bits/byte).\033[0m")

    if passed_count == total_count:
        print("\033[92mAll tests passed! Data appears random.\033[0m")
    elif passed_count >= total_count * 0.9:
        print("\033[93mMost tests passed. Minor deviations may be statistical noise.\033[0m")
    else:
        print("\033[91mSignificant test failures. Data may not be random.\033[0m")

    print("=" * 70)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Fetch samples from hardware RNG and perform randomness tests",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s /dev/ttyACM0                    # Read 1000 samples at 9600 baud
  %(prog)s /dev/ttyACM0 -b 115200 -n 5000  # Read 5000 samples at 115200 baud
  %(prog)s -f samples.txt                  # Test samples from file
  %(prog)s /dev/ttyACM0 -o samples.bin     # Save raw bytes to file
        """
    )

    parser.add_argument("device", nargs="?", help="Serial device (e.g., /dev/ttyACM0)")
    parser.add_argument("-b", "--baudrate", type=int, default=9600, help="Baud rate (default: 9600)")
    parser.add_argument("-n", "--num-samples", type=int, default=1000, help="Number of samples to read (default: 1000)")
    parser.add_argument("-f", "--file", help="Read samples from file instead of serial")
    parser.add_argument("-o", "--output", help="Save raw bytes to file")
    parser.add_argument("-q", "--quiet", action="store_true", help="Quiet mode (less verbose output)")

    args = parser.parse_args()

    if args.file:
        data = read_from_file(args.file)
    elif args.device:
        data = read_samples(args.device, args.baudrate, args.num_samples, verbose=not args.quiet)
    else:
        parser.print_help()
        sys.exit(1)

    if len(data) < 100:
        print("Error: Insufficient data collected. Need at least 100 bytes.", file=sys.stderr)
        sys.exit(1)

    if args.output:
        with open(args.output, 'wb') as f:
            f.write(data)
        print(f"Raw data saved to {args.output}", file=sys.stderr)

    run_all_tests(data, verbose=not args.quiet)


if __name__ == "__main__":
    main()
