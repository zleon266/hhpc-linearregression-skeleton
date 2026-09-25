.RECIPEPREFIX := >

CC ?= gcc
OPT ?= -O0
TARGET ?= linreg

CFLAGS := -std=gnu11 -Wall -Wextra -Wpedantic $(OPT)
LDLIBS := -lm

SRC := linreg.c gemm.c gemv.c gaussian.c rng.c
HDR := gaussian.h gemm.h gemv.h rng.h timer.h

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC) $(HDR)
>mkdir -p $(dir $@)
>$(CC) $(CFLAGS) -o $@ $(SRC) $(LDLIBS)

clean:
>rm -f linreg
>rm -rf bin
