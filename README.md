# NxN Matrix - Nx1 Vector[Nx1] Multiplier [IEEE 754 Single Precision Floating Point ]

## Introduction 

This is a floating point matrix-vector multiplier, that operates on a square matrix and a corresponding vector. 

## General Architecture

The general architecture of the core multiplier module can be seen in the figure below. 

<img src="./img/TensorUnit_GenArch.png">

Inside the core are NxN highly parallelized floating point multiplication modules that calculate the partial matrices in a minimum of 2 clock cycles. The output from this module is a NxN partial matrix. These outputs are then fed into another set of highly parallelized floating point accumulators. These floating point accumulators calculate the output in N clock cycles.

