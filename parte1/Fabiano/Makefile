CXX = g++
CXXSTD = -std=c++17
CXXFLAGS = $(CXXSTD) -Wall -g

TARGET = ProgettoLC

SOURCES_BNFC = Absyn.C Buffer.C Lexer.C Parser.C
SOURCES_NOSTRI = Build.cpp Comments.cpp Resolve.cpp Delete.cpp Positions.cpp PrettyPrint.cpp main.cpp

OBJECTS = $(SOURCES_BNFC:.C=.o) $(SOURCES_NOSTRI:.cpp=.o)

.PHONY: all demo clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(OBJECTS) -o $(TARGET)

Lexer.C: Config.l
	flex -Pconfig_ -oLexer.C Config.l

Parser.C Bison.H: Config.y
	bison -t -pconfig_ Config.y -o Parser.C

Lexer.o: Bison.H

%.o: %.C
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

demo: $(TARGET)
	@echo "=== Demo: test1.conf ==="
	./$(TARGET) test1.conf
	@echo ""
	@echo "=== Demo: test_commenti.conf ==="
	./$(TARGET) test_commenti.conf

test_funzioni: test_funzioni.o Build.o Comments.o Resolve.o Delete.o Positions.o Absyn.o Buffer.o Lexer.o Parser.o
	$(CXX) $(CXXFLAGS) test_funzioni.o Build.o Comments.o Resolve.o Delete.o Positions.o Absyn.o Buffer.o Lexer.o Parser.o -o test_funzioni

clean:
	rm -f *.o $(TARGET) Lexer.C Parser.C Bison.H
