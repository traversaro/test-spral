#!/bin/bash -e

echo "Check .pc file"
pkg-config --exists --print-errors --debug ipopt
pkg-config --validate --print-errors --debug ipopt

echo "Test the ipopt executable"
export OMP_CANCELLATION=TRUE
export OMP_PROC_BIND=TRUE
ipopt mytoy.nl | grep -q "Optimal Solution"

# Test linking against the ipopt library
cd test

${CXX} -I$PREFIX/include/coin-or -c -o cpp_example.o cpp_example.cpp
${CXX} -I$PREFIX/include/coin-or -c -o MyNLP.o MyNLP.cpp

# Deal with different linker flags
if [ $(uname -s) == 'Darwin' ]; then
  ${CXX} -L$PREFIX/lib -Wl,-rpath,$PREFIX/lib -lipopt \
    -I$PREFIX/include/coin-or -o cpp_example cpp_example.o MyNLP.o
else
  ${CXX} -L$PREFIX/lib -lipopt -I$PREFIX/include/coin-or -o cpp_example cpp_example.o MyNLP.o
fi

echo "Test mumps linear solver"
./cpp_example mumps | grep -q "Optimal Solution"
if [ $(uname -s) == 'Linux' ]; then
  echo "Test spral linear solver"
  # Environment variables needed by spral
  export OMP_CANCELLATION=TRUE
  export OMP_PROC_BIND=TRUE
  ./cpp_example spral | grep -q "Optimal Solution"
fi
