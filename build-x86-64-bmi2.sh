#!/bin/sh -e

cd official/src
rm -f nn-*.nnue
cp ../../nn-*.nnue .
make clean
CXXFLAGS="-DNNUE_EMBEDDING_OFF -D__DATE__='\"Nov 16 2020\"'" make ARCH=x86-64-bmi2 profile-build
make strip
cp stockfish ../../stockfish-x86-64-bmi2
