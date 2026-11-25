BEGIN {
  r[1] = 1000
  r[2] = 2200
  r[3] = 4700
  pi = 4 * atan2(1, 1)
}
/^SWEEP_BEGIN/ { begins++ }
/^SWEEP_END/ { ends++ }
/^f3db/ { fc[++nfc] = $3 }
/^gain1k/ { gain[++ngain] = $3 }
/^phase3db/ { phase[++nphase] = $3 }
END {
  if (begins != 3 || ends != 3 || nfc != 3 || ngain != 3 || nphase != 3) {
    print "VERIFY_FAIL: expected exactly three complete sweeps" > "/dev/stderr"
    exit 1
  }
  for (i = 1; i <= 3; i++) {
    reference = 1 / (2 * pi * r[i] * 100e-9)
    error = (fc[i] - reference) / reference
    if (error < 0) error = -error
    if (error > 0.01) {
      printf "VERIFY_FAIL: f3db index %d differs from RC reference by %.4f%%\n", i, error * 100 > "/dev/stderr"
      exit 1
    }
    printf "SUMMARY R=%g f3db_hz=%.6f gain1k_db=%.6f phase3db_rad=%.7f reference_fc_hz=%.6f\n", r[i], fc[i], gain[i], phase[i], reference
  }
  print "VERIFY_PASS: three sweeps, measurements present, f3db within 1% of 1/(2*pi*R*C)"
}
