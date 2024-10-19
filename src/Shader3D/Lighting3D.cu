#include <Lighting3D.cuh>

void Lighting3D::phongShading() {
    Render3D &render = Render3D::instance();
    Buffer3D &buffer = render.buffer;

    phongShadingKernel<<<buffer.blockCount, buffer.blockSize>>>(
        buffer.active, buffer.color, buffer.world, buffer.normal, buffer.texture,
        buffer.width, buffer.height
    );
    cudaDeviceSynchronize();
}

__global__ void phongShadingKernel(
    bool *buffActive, Vec4f *buffColor, Vec3f *buffWorld, Vec3f *buffNormal, Vec2f *buffTexture,
    int buffWidth, int buffHeight
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= buffWidth * buffHeight || !buffActive[i]) return;
    
    // We will apply simple directional lighting
    Vec3f lightDir = Vec3f(0, 0, 1);
    Vec3f n = buffNormal[i];

    // Calculate the cosine of the angle between the normal and the light direction
    float dot = n * lightDir;
    
    float cosA = dot / (n.mag() * lightDir.mag());
    if (cosA < 0) cosA = 0;

    float diff = 0.2 + 0.8 * cosA;

    // Apply the light
    buffColor[i] = buffColor[i] * diff;
}