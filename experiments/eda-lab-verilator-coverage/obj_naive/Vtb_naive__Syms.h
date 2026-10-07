// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_NAIVE__SYMS_H_
#define VERILATED_VTB_NAIVE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_naive.h"

// INCLUDE MODULE CLASSES
#include "Vtb_naive___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtb_naive__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_naive* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_naive___024root            TOP;

    // COVERAGE
    uint32_t __Vcoverage[27];

    // CONSTRUCTORS
    Vtb_naive__Syms(VerilatedContext* contextp, const char* namep, Vtb_naive* modelp);
    ~Vtb_naive__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
