# 四链接器对照：bfd / gold / lld / mold，同一批 .o 只换 -fuse-ld。
# 链接耗时由 run.sh 外部测量，Makefile 只负责可复现的编译与链接动作。
CXX ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -I.
NTU ?= 300

SRCDIR := src
OBJDIR := build/obj
BINDIR := build/bin
TU_SRCS := $(wildcard $(SRCDIR)/tu*.cpp)
TU_OBJS := $(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.o,$(TU_SRCS))
OBJS := $(TU_OBJS) $(OBJDIR)/main.o $(OBJDIR)/sumparts.o
LINKERS := bfd gold lld mold

.PHONY: all gen objects clean dirs
all: $(addprefix $(BINDIR)/bench-,$(LINKERS))

gen:
	bash gen_tus.sh $(NTU) $(SRCDIR)

dirs:
	mkdir -p $(OBJDIR) $(BINDIR)

# 调用 make 前必须先单独执行 gen 或 run.sh，确保 wildcard 在源码生成后展开。
objects: dirs $(OBJS)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp | dirs
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJDIR)/sumparts.o: sumparts.cpp work.hpp | dirs
	$(CXX) $(CXXFLAGS) -c sumparts.cpp -o $@

$(BINDIR)/bench-%: $(OBJS) | dirs
	$(CXX) $(CXXFLAGS) -fuse-ld=$* $(OBJS) -o $@

clean:
	rm -rf build src
