# compiles and runs the current homework
nvcc -diag-suppress=177 HW18/HW18SetupRandomMassesBroken.cu -o HW18/bounce -lglut -lm -lGLU -lGL

./HW18/bounce
