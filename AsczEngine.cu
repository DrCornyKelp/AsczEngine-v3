#include <FpsHandler.cuh>
#include <Mesh3D.cuh>
#include <Camera3D.cuh>

int main() {
    Mesh mesh(
        0, // ID
        Vecs3f({ // Position
            Vec3f(-1, -1, 0), Vec3f(1, -1, 0), Vec3f(1, 1, 0), Vec3f(-1, 1, 0)
        }),
        Vecs3f({ // Normal
            Vec3f(0, 0, 1), Vec3f(0, 0, 1), Vec3f(0, 0, 1), Vec3f(0, 0, 1)
        }),
        Vecs2f({ // Texture
            Vec2f(0, 0), Vec2f(1, 0), Vec2f(1, 1), Vec2f(0, 1)
        }),
        Vecs3uli({ // Faces
            Vec3uli(0, 1, 2), Vec3uli(0, 2, 3)
        })
    );

    Mesh3D MESH(mesh);

    MESH.printVertices();
    MESH.printFaces();

    Camera3D camera;
    camera.updateMVP();

    camera.mvp.print();

    return 0;
}