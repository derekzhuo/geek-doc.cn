// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_full__pch.h"

//============================================================
// Constructors

Vtb_full::Vtb_full(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_full__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_full::Vtb_full(const char* _vcname__)
    : Vtb_full(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_full::~Vtb_full() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_full___024root___eval_debug_assertions(Vtb_full___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_full___024root___eval_static(Vtb_full___024root* vlSelf);
void Vtb_full___024root___eval_initial(Vtb_full___024root* vlSelf);
void Vtb_full___024root___eval_settle(Vtb_full___024root* vlSelf);
void Vtb_full___024root___eval(Vtb_full___024root* vlSelf);

void Vtb_full::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_full::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_full___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_full___024root___eval_static(&(vlSymsp->TOP));
        Vtb_full___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_full___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_full___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_full::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vtb_full::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_full::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_full___024root___eval_final(Vtb_full___024root* vlSelf);

VL_ATTR_COLD void Vtb_full::final() {
    Vtb_full___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_full::hierName() const { return vlSymsp->name(); }
const char* Vtb_full::modelName() const { return "Vtb_full"; }
unsigned Vtb_full::threads() const { return 1; }
void Vtb_full::prepareClone() const { contextp()->prepareClone(); }
void Vtb_full::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vtb_full::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vtb_full::trace()' called on model that was Verilated without --trace option");
}
