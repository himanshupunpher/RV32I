#!/usr/bin/env bash
# run_all.sh
# Compiles and runs every testbench for the RV32I single-cycle core.
# Requires Icarus Verilog (iverilog/vvp). Usage: ./run_all.sh
set -u
cd "$(dirname "$0")"
mkdir -p work
FAIL=0

run() {
    local name=$1; shift
    local out="work/${name}.out"
    echo "############################################"
    echo "# ${name}"
    echo "############################################"
    if iverilog -g2012 -o "$out" "$@" ; then
        vvp "$out" | tee "work/${name}.log"
        if grep -q "TEST(S) FAILED" "work/${name}.log"; then
            FAIL=1
        fi
    else
        echo "COMPILE FAILED for ${name}"
        FAIL=1
    fi
    echo
}

run tb_alu              alu.v                tb/tb_alu.v
run tb_alu_control       alu_control.v        tb/tb_alu_control.v
run tb_alu_src_mux       alu_src_mux.v        tb/tb_alu_src_mux.v
run tb_writeback_mux     writeback_mux.v      tb/tb_writeback_mux.v
run tb_decoder           decoder.v            tb/tb_decoder.v
run tb_control_unit      control_unit.v       tb/tb_control_unit.v
run tb_pc_reg            pc_reg.v             tb/tb_pc_reg.v
run tb_next_pc_logic     next_pc_logic.v      tb/tb_next_pc_logic.v
run tb_regfile           regfile.v            tb/tb_regfile.v
run tb_imem              imem.v               tb/tb_imem.v
run tb_dmem              dmem.v               tb/tb_dmem.v
run tb_riscv_core        riscv_core.v pc_reg.v next_pc_logic.v imem.v dmem.v decoder.v \
                         regfile.v control_unit.v alu.v alu_control.v alu_src_mux.v \
                         writeback_mux.v tb/tb_riscv_core.v

echo "############################################"
if [ "$FAIL" -eq 0 ]; then
    echo "ALL TESTBENCHES PASSED"
else
    echo "SOME TESTBENCHES FAILED -- see logs above"
fi
echo "############################################"
exit $FAIL
