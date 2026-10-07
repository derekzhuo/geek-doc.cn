// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_FULL__SYMS_H_
#define VERILATED_VTB_FULL__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_full.h"

// INCLUDE MODULE CLASSES
#include "Vtb_full___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtb_full__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_full* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_full___024root             TOP;

    // COVERAGE
    uint32_t __Vcoverage[31];

    // CONSTRUCTORS
    Vtb_full__Syms(VerilatedContext* contextp, const char* namep, Vtb_full* modelp);
    ~Vtb_full__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
