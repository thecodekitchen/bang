#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

#include <stdio.h>
#include <vector>

struct Vec3f
{
    float x, y, z;
};

struct Vec2f
{
    float u, v;
};

struct Vec4f
{
    float r, g, b, a;
};

template <typename T>
struct Slice {
    T* data;
    size_t len;

    Slice() : data(nullptr), len(0) {}

    Slice(const T* in_data, size_t in_len) {
        if (in_data && in_len > 0) {
            len = in_len;
            data = new T[in_len];
            memcpy(data, in_data, sizeof(T) * len);
        } else {
            len = 0;
            data = nullptr;
        }
    }
};

struct Material {
    Vec3f ambient;
    Vec3f diffuse;
    Vec3f specular;
    float shininess;
};

struct MeshData {
    Slice<Vec3f> vertices;
    Slice<Vec3f> normals;
    Slice<Vec2f> texCoords;
    Slice<Vec4f> colors;
    Slice<int>   indices;

    Material material;
};

static void processMesh(aiMesh* mesh, const aiMatrix4x4& transformation, const aiScene* scene, 
                        std::vector<Vec3f>& vertices, std::vector<Vec3f>& normals, 
                        std::vector<Vec2f>& texCoords, std::vector<Vec4f>& colors, 
                        std::vector<int>& indices, Material& material);
static void processNode(aiNode* node, const aiMatrix4x4& transformation, const aiScene* scene, 
                        std::vector<Vec3f>& vertices, std::vector<Vec3f>& normals, 
                        std::vector<Vec2f>& texCoords, std::vector<Vec4f>& colors, 
                        std::vector<int>& indices, Material& material);

void processNode(aiNode* node, const aiMatrix4x4& transformation, const aiScene* scene, 
                 std::vector<Vec3f>& vertices, std::vector<Vec3f>& normals, 
                 std::vector<Vec2f>& texCoords, std::vector<Vec4f>& colors, 
                 std::vector<int>& indices, Material& material) {
    auto currentTransformation = transformation * node->mTransformation;
    for (auto i = 0u; i < node->mNumMeshes; i++) {
        processMesh(scene->mMeshes[node->mMeshes[i]], currentTransformation, scene, 
                    vertices, normals, texCoords, colors, indices, material);
    }
    for (auto i = 0u; i < node->mNumChildren; i++) {
        processNode(node->mChildren[i], currentTransformation, scene, 
                    vertices, normals, texCoords, colors, indices, material);
    }
}

void processMesh(aiMesh* mesh, const aiMatrix4x4& transformation, const aiScene* scene, 
                 std::vector<Vec3f>& vertices, std::vector<Vec3f>& normals, 
                 std::vector<Vec2f>& texCoords, std::vector<Vec4f>& colors, 
                 std::vector<int>& indices, Material& material) {
    unsigned int lastNVertices = vertices.size();
    // printf("Processing mesh with %u vertices\n", mesh->mNumVertices);
    // printf("Has normals: %s\n", mesh->HasNormals() ? "Yes" : "No");
    // printf("Has texture coords: %s\n", mesh->HasTextureCoords(0) ? "Yes" : "No");
    // printf("Has vertex colors: %s\n", mesh->HasVertexColors(0) ? "Yes" : "No");
    // printf("Has material: %s\n", mesh->mMaterialIndex >= 0 ? "Yes" : "No");
    for (auto i = 0u; i < mesh->mNumVertices; i++) {
        // Vertices
        auto v = transformation * mesh->mVertices[i];
        vertices.push_back(Vec3f{ v.x, v.y, v.z });

        // Normals
        if (mesh->HasNormals()) {
            auto n = transformation * mesh->mNormals[i];
            n.Normalize();
            normals.push_back(Vec3f{ n.x, n.y, n.z });
        }

        // Texture Coordinates
        if (mesh->HasTextureCoords(0)) {
            texCoords.push_back(Vec2f{ mesh->mTextureCoords[0][i].x, mesh->mTextureCoords[0][i].y });
        }

        // Colors
        if (mesh->HasVertexColors(0)) {
            colors.push_back(Vec4f{ mesh->mColors[0][i].r, mesh->mColors[0][i].g, 
                                    mesh->mColors[0][i].b, mesh->mColors[0][i].a });
        }
    }

    for (auto i = 0u; i < mesh->mNumFaces; i++) {
        aiFace face = mesh->mFaces[i];
        for (auto j = 0u; j < face.mNumIndices - 2; j++) {
            indices.push_back(lastNVertices + face.mIndices[0]);
            indices.push_back(lastNVertices + face.mIndices[j + 1]);
            indices.push_back(lastNVertices + face.mIndices[j + 2]);
        }
    }

    if (mesh->mMaterialIndex >= 0) {
        aiMaterial* ai_material = scene->mMaterials[mesh->mMaterialIndex];
        
        aiColor3D color(0.f, 0.f, 0.f);
        float shininess = 0.0f;

        if (AI_SUCCESS == ai_material->Get(AI_MATKEY_COLOR_AMBIENT, color))
            material.ambient = Vec3f{color.r, color.g, color.b};

        if (AI_SUCCESS == ai_material->Get(AI_MATKEY_COLOR_DIFFUSE, color))
            material.diffuse = Vec3f{color.r, color.g, color.b};

        if (AI_SUCCESS == ai_material->Get(AI_MATKEY_COLOR_SPECULAR, color))
            material.specular = Vec3f{color.r, color.g, color.b};

        if (AI_SUCCESS == ai_material->Get(AI_MATKEY_SHININESS, shininess))
            material.shininess = shininess;

        // printf("Material properties:\n");
        // printf("  Ambient: %f %f %f\n", material.ambient.x, material.ambient.y, material.ambient.z);
        // printf("  Diffuse: %f %f %f\n", material.diffuse.x, material.diffuse.y, material.diffuse.z);
        // printf("  Specular: %f %f %f\n", material.specular.x, material.specular.y, material.specular.z);
        // printf("  Shininess: %f\n", material.shininess);
    }
}

extern "C" MeshData load_mesh_data(const char* filename);
extern "C" void     free_mesh_data(MeshData* mesh_data);

void free_mesh_data(MeshData* mesh_data) {
    if (!mesh_data) return;

    delete[] mesh_data->vertices.data;
    delete[] mesh_data->normals.data;
    delete[] mesh_data->texCoords.data;
    delete[] mesh_data->colors.data;
    delete[] mesh_data->indices.data;

    mesh_data->vertices.data = nullptr;
    mesh_data->vertices.len = 0;
    
    mesh_data->normals.data = nullptr;
    mesh_data->normals.len = 0;
    
    mesh_data->texCoords.data = nullptr;
    mesh_data->texCoords.len = 0;
    
    mesh_data->colors.data = nullptr;
    mesh_data->colors.len = 0;
    
    mesh_data->indices.data = nullptr;
    mesh_data->indices.len = 0;
}

MeshData load_mesh_data(const char* filename) {
    Assimp::Importer importer;
    unsigned int flags = aiProcess_Triangulate | aiProcess_FlipUVs | aiProcess_GenSmoothNormals;
    const aiScene* scene = importer.ReadFile(filename, flags);

    if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) {
        printf("ERROR Assimp: %s\n", importer.GetErrorString());
        return MeshData();
    }

    // printf("Scene loaded successfully.\n");
    // printf("Number of meshes: %u\n", scene->mNumMeshes);

    std::vector<Vec3f> vertices, normals;
    std::vector<Vec2f> texCoords;
    std::vector<Vec4f> colors;
    std::vector<int>   indices;
    Material material;

    processNode(scene->mRootNode, aiMatrix4x4(), scene, vertices, normals, texCoords, colors, indices, material);

    // printf("Final data:\n");
    // printf("Vertices: %zu\n", vertices.size());
    // printf("Normals: %zu\n", normals.size());
    // printf("TexCoords: %zu\n", texCoords.size());
    // printf("Colors: %zu\n", colors.size());
    // printf("Indices: %zu\n", indices.size());

    return {
        {vertices.data(), vertices.size()},
        {normals.data(), normals.size()},
        {texCoords.data(), texCoords.size()},
        {colors.data(), colors.size()},
        {indices.data(), indices.size()},
        material
    };
}
// #include <assimp/Importer.hpp>
// #include <assimp/scene.h>
// #include <assimp/postprocess.h>

// #include <stdio.h>
// #include <vector>

// struct Vec3f
// {
//     float x, y, z;
// };

// template <typename T>
// struct Slice {
//     T* data;
//     size_t len;

//     Slice() {
//         data = nullptr;
//         len = 0;
//     }

//     Slice(const T* in_data, size_t in_len) {
//         if (in_data && in_len > 0) {
//             len = in_len;
//             data = new T[in_len];
//             memcpy(data, in_data, sizeof(T) * len);
//         } else {
//             len = 0;
//             data = nullptr;
//         }
//     }
// };

// struct MeshData {
//     Slice<Vec3f> vertices;
//     Slice<int>   indices;
// };

// static void processMesh(aiMesh* mesh, const aiMatrix4x4& transformation, const aiScene* scene, std::vector<Vec3f>& vertices, std::vector<int>& indices);
// static void processNode(aiNode* node, const aiMatrix4x4& transformation, const aiScene* scene, std::vector<Vec3f>& vertices, std::vector<int>& indices);

// //-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// void processNode(aiNode* node, const aiMatrix4x4& transformation, const aiScene* scene, std::vector<Vec3f>& vertices, std::vector<int>& indices) {
//     auto currentTransformation = transformation * node->mTransformation;
//     for (auto i = 0; i < node->mNumMeshes; i++) {
//         processMesh(scene->mMeshes[node->mMeshes[i]], currentTransformation, scene, vertices, indices);
//     }
//     for (auto i = 0; i < node->mNumChildren; i++) {
//         processNode(node->mChildren[i], currentTransformation, scene, vertices, indices);
//     }
// }

// //-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// void processMesh(aiMesh* mesh, const aiMatrix4x4& transformation, const aiScene* scene, std::vector<Vec3f>& vertices, std::vector<int>& indices) {
//     unsigned int lastNVertices = vertices.size();
//     for (auto i = 0; i < mesh->mNumVertices; i++) {
//         auto v = transformation * mesh->mVertices[i];
//         vertices.push_back(Vec3f{ v[0], v[1], v[2] });
//     }

//     for (auto i = 0; i < mesh->mNumFaces; i++) {
//         aiFace face = mesh->mFaces[i];
//         for (auto j = 0; j < face.mNumIndices - 2; j++) {
//             indices.push_back(lastNVertices + face.mIndices[0]);
//             indices.push_back(lastNVertices + face.mIndices[j + 1]);
//             indices.push_back(lastNVertices + face.mIndices[j + 2]);
//         }
//     }
// }

// //-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// extern "C" MeshData load_mesh_data(const char* filename);
// extern "C" void     free_mesh_data(MeshData* mesh_data);

// void free_mesh_data(MeshData* mesh_data) {
//     if (!mesh_data) return;

//     if (mesh_data->vertices.data) {
//         delete[] mesh_data->vertices.data;
//     }

//     if (mesh_data->indices.data) {
//         delete[] mesh_data->indices.data;
//     }

//     mesh_data->vertices.data = nullptr;
//     mesh_data->vertices.len = 0;
    
//     mesh_data->indices.data = nullptr;
//     mesh_data->indices.len = 0;
// }

// MeshData load_mesh_data(const char* filename) {
//     Assimp::Importer importer;
//     const aiScene* scene = importer.ReadFile(filename, 0);

//     if (!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode) {
//         printf("ERROR Assimp: %s\n", importer.GetErrorString());
//         MeshData data;
//         return data;
//     }

//     std::vector<Vec3f> vertices;
//     std::vector<int>   indices;
//     processNode(scene->mRootNode, aiMatrix4x4(), scene, vertices, indices);

//     return {
//         {vertices.data(), vertices.size()},
//         {indices.data(), indices.size()}
//     };
// }

