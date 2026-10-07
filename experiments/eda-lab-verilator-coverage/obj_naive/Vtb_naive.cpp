// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_naive__pch.h"

//============================================================
// Constructors

Vtb_naive::Vtb_naive(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_naive__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_naive::Vtb_naive(const char* _vcname__)
    : Vtb_naive(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_naive::~Vtb_naive() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_naive___024root___eval_debug_assertions(Vtb_naive___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_naive___024root___eval_static(Vtb_naive___024root* vlSelf);
void Vtb_naive___024root___eval_initial(Vtb_naive___024root* vlSelf);
void Vtb_naive___024root___eval_settle(Vtb_naive___024root* vlSelf);
void Vtb_naive___024root___eval(Vtb_naive___024root* vlSelf);

void Vtb_naive::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_naive::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_naive___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_naive___024root___eval_static(&(vlSymsp->TOP));
        Vtb_naive___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_naive___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_naive___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_naive::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vtb_naive::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_naive::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_naive___024root___eval_final(Vtb_naive___024root* vlSelf);

VL_ATTR_COLD void Vtb_naive::final() {
    Vtb_naive___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_naive::hierName() const { return vlSymsp->name(); }
const char* Vtb_naive::modelName() const { return "Vtb_naive"; }
unsigned Vtb_naive::threads() const { return 1; }
void Vtb_naive::prepareClone() const { contextp()->prepareClone(); }
void Vtb_naive::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vtb_naive::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vtb_naive::trace()' called on model that was Verilated without --trace option");
}
