#include <Mesh3D.cuh>

// Mesh struct

Mesh::Mesh(UInt id, Vecs3f &world, Vecs3f &normal, Vecs2f &texture, Vecs4f &color, Vecs3uli &faces) :
    meshID(world.size(), id), world(world), normal(normal),
    texture(texture), color(color), faces(faces)
{}

Mesh::Mesh(Mesh &mesh) :
    meshID(mesh.meshID), world(mesh.world), normal(mesh.normal),
    texture(mesh.texture), color(mesh.color), faces(mesh.faces)
{}

Mesh Mesh::operator+=(Mesh &mesh) {
    ULLInt oldSize = world.size();

    meshID.insert(meshID.end(), mesh.meshID.begin(), mesh.meshID.end());
    world.insert(world.end(), mesh.world.begin(), mesh.world.end());
    normal.insert(normal.end(), mesh.normal.begin(), mesh.normal.end());
    texture.insert(texture.end(), mesh.texture.begin(), mesh.texture.end());
    color.insert(color.end(), mesh.color.begin(), mesh.color.end());
    faces.insert(faces.end(), mesh.faces.begin(), mesh.faces.end());

    // Shift the faces indices
    for (ULLInt i = oldSize; i < faces.size(); i++) {
        faces[i] += oldSize;
    }
    return *this;
}

// Constructor

Mesh3D::Mesh3D(ULLInt numVs, ULLInt numFs) :
    numVs(numVs), numFs(numFs)
{
    mallocVertices();
    mallocFaces();
}

Mesh3D::Mesh3D(UInt id, Vecs3f &world, Vecs3f &normal, Vecs2f &texture, Vecs4f &color, Vecs3uli &faces) :
    numVs(world.size()), numFs(faces.size())
{
    mallocVertices();
    mallocFaces();
    uploadData(id, world, normal, texture, color, faces);
}

Mesh3D::Mesh3D(Mesh &mesh) :
    numVs(mesh.world.size()), numFs(mesh.faces.size())
{
    mallocVertices();
    mallocFaces();
    uploadData(mesh.meshID[0], mesh.world, mesh.normal, mesh.texture, mesh.color, mesh.faces);
}

Mesh3D::~Mesh3D() {
    freeVertices();
    freeFaces();
}

// Memory management

void Mesh3D::mallocVertices() {
    blockNumVs = (numVs + blockSize - 1) / blockSize;
    cudaMalloc(&meshID, numVs * sizeof(UInt));
    cudaMalloc(&world, numVs * sizeof(Vec3f));
    cudaMalloc(&normal, numVs * sizeof(Vec3f));
    cudaMalloc(&texture, numVs * sizeof(Vec2f));
    cudaMalloc(&color, numVs * sizeof(Vec4f));
}

void Mesh3D::resizeVertices(ULLInt numVs) {
    freeVertices();
    this->numVs = numVs;
    mallocVertices();
}

void Mesh3D::freeVertices() {
    cudaFree(meshID);
    cudaFree(world);
    cudaFree(normal);
    cudaFree(texture);
    cudaFree(color);
}

void Mesh3D::mallocFaces() {
    blockNumFs = (numFs + blockSize - 1) / blockSize;
    cudaMalloc(&faces, numFs * sizeof(Vec3uli));
}

void Mesh3D::resizeFaces(ULLInt numFs) {
    freeFaces();
    this->numFs = numFs;
    mallocFaces();
}

void Mesh3D::freeFaces() {
    cudaFree(faces);
}

// Upload host data to device

void Mesh3D::uploadData(UInt id, Vecs3f &world, Vecs3f &normal, Vecs2f &texture, Vecs4f &color, Vecs3uli &faces) {
    // Vertices
    setMeshIDKernel<<<blockNumVs, blockSize>>>(this->meshID, numVs, id);
    cudaMemcpy(this->world, world.data(), world.size() * sizeof(Vec3f), cudaMemcpyHostToDevice);
    cudaMemcpy(this->normal, normal.data(), normal.size() * sizeof(Vec3f), cudaMemcpyHostToDevice);
    cudaMemcpy(this->texture, texture.data(), texture.size() * sizeof(Vec2f), cudaMemcpyHostToDevice);
    cudaMemcpy(this->color, color.data(), color.size() * sizeof(Vec4f), cudaMemcpyHostToDevice);
    // Faces indices
    cudaMemcpy(this->faces, faces.data(), faces.size() * sizeof(Vec3uli), cudaMemcpyHostToDevice);
}

// Mesh operators

void Mesh3D::operator+=(Mesh3D &mesh) {
    // Resize vertices
    ULLInt newNumVs = numVs + mesh.numVs;
    UInt *newMeshID;
    Vec3f *newWorld;
    Vec3f *newNormal;
    Vec2f *newTexture;
    Vec4f *newColor;
    cudaMalloc(&newMeshID, newNumVs * sizeof(UInt));
    cudaMalloc(&newWorld, newNumVs * sizeof(Vec3f));
    cudaMalloc(&newNormal, newNumVs * sizeof(Vec3f));
    cudaMalloc(&newTexture, newNumVs * sizeof(Vec2f));
    cudaMalloc(&newColor, newNumVs * sizeof(Vec4f));
    // Copy old data
    cudaMemcpy(newMeshID, meshID, numVs * sizeof(UInt), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newWorld, world, numVs * sizeof(Vec3f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newNormal, normal, numVs * sizeof(Vec3f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newTexture, texture, numVs * sizeof(Vec2f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newColor, color, numVs * sizeof(Vec4f), cudaMemcpyDeviceToDevice);
    // Copy new data
    cudaMemcpy(newMeshID + numVs, mesh.meshID, mesh.numVs * sizeof(UInt), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newWorld + numVs, mesh.world, mesh.numVs * sizeof(Vec3f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newNormal + numVs, mesh.normal, mesh.numVs * sizeof(Vec3f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newTexture + numVs, mesh.texture, mesh.numVs * sizeof(Vec2f), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newColor + numVs, mesh.color, mesh.numVs * sizeof(Vec4f), cudaMemcpyDeviceToDevice);
    // Free old data
    freeVertices();
    // Update vertices
    meshID = newMeshID;
    world = newWorld;
    normal = newNormal;
    texture = newTexture;
    color = newColor;

    // Resize faces (with offset for the added vertices)
    ULLInt newNumFs = numFs + mesh.numFs;
    Vec3uli *newFaces;
    cudaMalloc(&newFaces, newNumFs * sizeof(Vec3uli));
    cudaMemcpy(newFaces, faces, numFs * sizeof(Vec3uli), cudaMemcpyDeviceToDevice);
    cudaMemcpy(newFaces + numFs, mesh.faces, mesh.numFs * sizeof(Vec3uli), cudaMemcpyDeviceToDevice);
    incrementFaceIdxKernel<<<blockNumFs, blockSize>>>(newFaces, mesh.numFs, numVs);
    cudaFree(faces);
    faces = newFaces;

    // Update number of vertices and faces
    numVs = newNumVs;
    numFs = newNumFs;
    blockNumVs = (numVs + blockSize - 1) / blockSize;
    blockNumFs = (numFs + blockSize - 1) / blockSize;
}

// Transformations

void Mesh3D::translate(UInt mID, Vec3f t) {
    translateVertexKernel<<<blockNumVs, blockSize>>>(world, meshID, numVs, mID, t);
}
void Mesh3D::rotate(UInt mID, Vec3f origin, Vec3f rot) {
    rotateVertexKernel<<<blockNumVs, blockSize>>>(world, meshID, numVs, mID, origin, rot);
}
void Mesh3D::scale(UInt mID, Vec3f origin, Vec3f scl) {
    scaleVertexKernel<<<blockNumVs, blockSize>>>(world, meshID, numVs, mID, origin, scl);
}

// DEBUG

void Mesh3D::printVertices(bool p_world, bool p_normal, bool p_tex, bool p_color, bool p_mID) {
    UInt *hMeshID = new UInt[numVs];
    Vec3f *hworld = new Vec3f[numVs];
    Vec3f *hNormal = new Vec3f[numVs];
    Vec2f *hTexture = new Vec2f[numVs];
    Vec4f *hColor = new Vec4f[numVs];

    cudaMemcpy(hMeshID, meshID, numVs * sizeof(UInt), cudaMemcpyDeviceToHost);
    cudaMemcpy(hworld, world, numVs * sizeof(Vec3f), cudaMemcpyDeviceToHost);
    cudaMemcpy(hNormal, normal, numVs * sizeof(Vec3f), cudaMemcpyDeviceToHost);
    cudaMemcpy(hTexture, texture, numVs * sizeof(Vec2f), cudaMemcpyDeviceToHost);
    cudaMemcpy(hColor, color, numVs * sizeof(Vec4f), cudaMemcpyDeviceToHost);

    for (ULLInt i = 0; i < numVs; i++) {
        printf("Vertex %llu\n", i);
        if (p_mID) printf("| meshID: %u\n", hMeshID[i]);
        if (p_world) printf("| world: (%f, %f, %f)\n", hworld[i].x, hworld[i].y, hworld[i].z);
        if (p_normal) printf("| Normal: (%f, %f, %f)\n", hNormal[i].x, hNormal[i].y, hNormal[i].z);
        if (p_tex) printf("| Tex: (%f, %f)\n", hTexture[i].x, hTexture[i].y);
        if (p_color) printf("| Color: (%f, %f, %f, %f)\n", hColor[i].x, hColor[i].y, hColor[i].z, hColor[i].w);
    }

    delete[] hMeshID, hworld, hNormal, hTexture, hColor;
}

void Mesh3D::printFaces() {
    Vec3uli *hFaces = new Vec3uli[numFs];
    cudaMemcpy(hFaces, faces, numFs * sizeof(Vec3uli), cudaMemcpyDeviceToHost);

    for (ULLInt i = 0; i < numFs; i++) {
        printf("Face %llu: (%lu, %lu, %lu)\n", i, hFaces[i].x, hFaces[i].y, hFaces[i].z);
    }

    delete[] hFaces;
}

// Kernel for preparing vertices
__global__ void incrementFaceIdxKernel(Vec3uli *faces, ULLInt numFs, ULLInt offset) {
    ULLInt idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numFs) faces[idx] += offset;
}

__global__ void setMeshIDKernel(UInt *meshID, ULLInt numVs, UInt id) {
    ULLInt idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < numVs) meshID[idx] = id;
}

// Kernel for transforming vertices
__global__ void translateVertexKernel(Vec3f *world, UInt *meshID, ULLInt numVs, UInt mID, Vec3f t) {
    ULLInt idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numVs || meshID[idx] != mID) return;

    world[idx].translate(t);
}
__global__ void rotateVertexKernel(Vec3f *world, UInt *meshID, ULLInt numVs, UInt mID, Vec3f origin, Vec3f rot) {
    ULLInt idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numVs || meshID[idx] != mID) return;

    world[idx].rotate(origin, rot);
}
__global__ void scaleVertexKernel(Vec3f *world, UInt *meshID, ULLInt numVs, UInt mID, Vec3f origin, Vec3f scl) {
    ULLInt idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= numVs || meshID[idx] != mID) return;

    world[idx].scale(origin, scl);
}