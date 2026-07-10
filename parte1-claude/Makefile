# GNU make. Tools: g++ (C++17), Bison, Flex.
CXX      = g++
CXXFLAGS = -std=c++17 -Wall
EXE      = confparser
SRCS     = parser.tab.cpp lex.yy.cpp config.cpp main.cpp

all: $(EXE)

$(EXE): $(SRCS) config.h
	$(CXX) $(CXXFLAGS) -o $@ $(SRCS)

# Bison first: it also generates parser.tab.hpp, needed by the lexer.
parser.tab.cpp parser.tab.hpp: parser.y
	bison -d -o parser.tab.cpp parser.y

lex.yy.cpp: lexer.l parser.tab.hpp
	flex -o $@ lexer.l

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
	rm -f $(EXE) parser.tab.cpp parser.tab.hpp lex.yy.cpp out1.tmp out2.tmp

.PHONY: all demo clean
