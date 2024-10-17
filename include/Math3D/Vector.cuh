#ifndef VECTOR_CUH
#define VECTOR_CUH

#include <iostream>
#include <vector>
#include <cstdio>
#include <cmath>

#define Vecs2f std::vector<Vec2f>
#define Vecs3f std::vector<Vec3f>
#define Vecs4f std::vector<Vec4f>
#define Vecs3uli std::vector<Vec3uli>

struct Vec2f {
    float x, y;
    __host__ __device__ Vec2f();
    __host__ __device__ Vec2f(float x, float y);
};

struct Vec3uli { // For faces indices
    unsigned long int x, y, z;
    __host__ __device__ Vec3uli();
    __host__ __device__ Vec3uli(int x, int y, int z);

    __host__ __device__ void operator+=(unsigned long int d);
};

struct Vec4f; // Forward declaration
struct Vec3f {
    float x, y, z;
    __host__ __device__ Vec3f();
    __host__ __device__ Vec3f(float x, float y, float z);
    __host__ __device__ Vec4f toVec4f();

    // Basic operations
    __host__ __device__ Vec3f operator+(const Vec3f &vec);
    __host__ __device__ Vec3f operator-(const Vec3f &vec);
    __host__ __device__ Vec3f operator*(const float scl);
    // Advanced operations
    __host__ __device__ float operator*(const Vec3f &vec); // Dot product
    __host__ __device__ Vec3f operator&(const Vec3f &vec); // Cross product

    void print() { // Will remove this later
        printf("Vec3(%f, %f, %f)\n", x, y, z);
    }
};

struct Vec4f {
    float x, y, z, w;
    __host__ __device__ Vec4f();
    __host__ __device__ Vec4f(float x, float y, float z, float w);

    void print() { // Will remove this later
        printf("Vec4(%f, %f, %f, %f)\n", x, y, z, w);
    }
};

#endif