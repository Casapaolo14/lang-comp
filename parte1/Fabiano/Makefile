CXX = g++
CXXSTD = -std=c++17
CXXFLAGS = $(CXXSTD) -Wall -g

TARGET = ProgettoLC

SOURCES_BNFC = Absyn.C Buffer.C Lexer.C Parser.C
SOURCES_NOSTRI = Costruzione.cpp Commenti.cpp Risoluzione.cpp Cancellazione.cpp Posizioni.cpp StampaFormattata.cpp main.cpp

OBJECTS = $(SOURCES_BNFC:.C=.o) $(SOURCES_NOSTRI:.cpp=.o)

.PHONY: all demo clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(OBJECTS) -o $(TARGET)

Lexer.C: Grammatica.l
	flex -Pgrammatica_ -oLexer.C Grammatica.l

Parser.C Bison.H: Grammatica.y
	bison -t -pgrammatica_ Grammatica.y -o Parser.C

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

test_funzioni: test_funzioni.o Costruzione.o Commenti.o Risoluzione.o Cancellazione.o Posizioni.o Absyn.o Buffer.o Lexer.o Parser.o
	$(CXX) $(CXXFLAGS) test_funzioni.o Costruzione.o Commenti.o Risoluzione.o Cancellazione.o Posizioni.o Absyn.o Buffer.o Lexer.o Parser.o -o test_funzioni

clean:
	rm -f *.o $(TARGET) Lexer.C Parser.C Bison.H
