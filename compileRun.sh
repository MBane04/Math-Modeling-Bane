# compiles and runs the current homework
nvcc -diag-suppress=177 HW19/HW19SetupRandomMassesBroken.cu -o HW19/bounce -lglut -lm -lGLU -lGL

./HW19/bounce
