# Floating Point Matrix-Vector Multiplier [IEEE 754 Single Precision Floating Point ]

## Introduction 

This is a floating point matrix-vector multiplier, that operates on a square matrix and a corresponding vector. The module is designed to be highly modular. By changing the parameter specified in the [TensorUnit](./src/TensorUnit.v), this IP can be customized for any square matrix of size NxN and the corresponding vector of Nx1 size. 

## General Architecture

The general architecture of the core multiplier module can be seen in the figure below. 

<img src="./img/TensorUnit_GenArch.png">

Inside the core are NxN highly parallelized floating point multiplication modules that calculate the partial matrices in a minimum of 2 clock cycles. The output from this module is a NxN partial matrix. These outputs are then fed into another set of highly parallelized floating point accumulators. These floating point accumulators calculate the output in N clock cycles, where N is the size of the input matrix and vector.

<br><br>
# Output Verification, N = 2

When N is set to 2, the module generates a 2x2 matrix - 2x1 vector multiplier. The input output simulation waveform for N=2 can be seen below. 

<img src="./img/output_2x2.png">

Following is the output received from MATLAB

<img width=100 src="./img/matrix2x2_vector2x1.png">



<br><br>

# Output Verification, N = 3
When N is set to 3, the module generates a 3x3 matrix - 3x1 vector multiplier. The output simulation waveform for N=3 can be seen below. 


<img src="./img/Matrix3x3_OK.png">

Following is the output received from MATLAB

<img width=200 src="./img/matrix3x3_vector3x1.png">

<br><br>

# Output Verification, N = 10
When N is set to 3, the module generates a 10x10 matrix - 10x1 vector multiplier. The output simulation waveform for N=10 can be seen below. 

<img src="./img/Matrix10x10_OKC.jpg">

Let's see what are where. 

<img src="./img/Matrix10x10_OK_Analysis.jpg">

Following is the output received from MATLAB

<img width=300 src="./img/matrix10x10_vector10x1.png">