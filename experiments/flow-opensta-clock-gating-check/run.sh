#!/bin/bash
# Reproduce all cases of the clock gating check experiment with OpenSTA 2.0.17.
set -e
sta -no_init -version
sta -no_init -exit help_gating.tcl
sta -no_init -exit case_a_nocmd.tcl
sta -no_init -exit case_b_check.tcl
sta -no_init -exit case_c_slow.tcl
