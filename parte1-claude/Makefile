# GNU make. Tools: g++ (C++17), Bison, Flex.
CXX      = g++
CXXFLAGS = -std=c++17 -Wall
EXE      = confparser
SRCS     = grammatica.tab.cpp lessico.yy.cpp configurazione.cpp main.cpp

all: $(EXE)

$(EXE): $(SRCS) configurazione.h
	$(CXX) $(CXXFLAGS) -o $@ $(SRCS)

# Bison first: it also generates grammatica.tab.hpp, needed by the lexer.
grammatica.tab.cpp grammatica.tab.hpp: grammatica.y
	bison -d -o grammatica.tab.cpp grammatica.y

lessico.yy.cpp: lessico.l grammatica.tab.hpp
	flex -o $@ lessico.l

demo: $(EXE)
	@echo "=== example from the assignment: parse + serialization (comments preserved) ==="
	./$(EXE) tests/example.conf
	@echo
	@echo "=== reference chains, local and cross-section ==="
	./$(EXE) tests/refs.conf
	@echo
	@echo "=== redefinition in the same section: warning, parsing continues ==="
	./$(EXE) tests/warn.conf
	@echo
	@echo "=== duplicate section: blocking error (failure expected) ==="
	-./$(EXE) tests/dupsection.conf
	@echo
	@echo "=== undefined reference: blocking error (failure expected) ==="
	-./$(EXE) tests/badref.conf
	@echo
	@echo "=== round-trip: serializing, re-parsing and re-serializing gives the same text ==="
	./$(EXE) tests/example.conf > out1.tmp
	./$(EXE) out1.tmp > out2.tmp
	cmp out1.tmp out2.tmp && echo "round-trip OK"
	rm -f out1.tmp out2.tmp

clean:
	rm -f $(EXE) grammatica.tab.cpp grammatica.tab.hpp lessico.yy.cpp out1.tmp out2.tmp

.PHONY: all demo clean
