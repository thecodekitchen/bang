package bang

BasicVertexSrc :: `#version 330 core
layout (location = 0) in vec3 aPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    gl_Position = projection * view * model * vec4(aPos.x, aPos.y, aPos.z, 1.0);
}`

BasicFragmentSrc :: `#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0, 0.5, 0.2, 1.0); // Orange color
}`

AdvancedVertexSrc :: `#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 FragPos;
out vec3 Normal;
out vec2 TexCoords;

void main() {
    FragPos = vec3(model * vec4(aPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;
    TexCoords = aTexCoords;
    gl_Position = projection * view * vec4(FragPos, 1.0);
}`

// AdvancedFragmentSrc :: `#version 330 core
// in vec3 FragPos;
// in vec3 Normal;
// in vec2 TexCoords;

// uniform vec3 viewPos;
// uniform vec3 lightPos;
// uniform vec3 lightColor;
// uniform vec3 diffuseColor;
// uniform vec3 specularColor;
// uniform float shininess;

// out vec4 FragColor;

// void main() {
//     // Ambient
//     float ambientStrength = 0.1;
//     vec3 ambient = ambientStrength * lightColor;
    
//     // Diffuse
//     vec3 norm = normalize(Normal);
//     vec3 lightDir = normalize(lightPos - FragPos);
//     float diff = max(dot(norm, lightDir), 0.0);
//     vec3 diffuse = diff * lightColor * diffuseColor;
    
//     // Specular
//     float specularStrength = 0.5;
//     vec3 viewDir = normalize(viewPos - FragPos);
//     vec3 reflectDir = reflect(-lightDir, norm);
//     float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
//     vec3 specular = specularStrength * spec * lightColor * specularColor;
    
//     vec3 result = ambient + diffuse + specular;
//     FragColor = vec4(result, 1.0);
// }`

AdvancedFragmentSrc :: `#version 330 core

in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;

#define MAX_LIGHTS 10

struct Light {
    vec3 position;
    vec3 color;
    float intensity;
};

uniform Light lights[MAX_LIGHTS];
uniform int numLights;
uniform vec3 viewPos;
uniform vec3 diffuseColor;
uniform vec3 specularColor;
uniform float shininess;

out vec4 FragColor;

void main() {
    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(viewPos - FragPos);

    vec3 result = vec3(0.0);

    for(int i = 0; i < numLights; i++) {
        // Ambient
        float ambientStrength = 0.1;
        vec3 ambient = ambientStrength * lights[i].color;
        
        // Diffuse
        vec3 lightDir = normalize(lights[i].position - FragPos);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = diff * lights[i].color * diffuseColor;
        
        // Specular
        float specularStrength = 0.5;
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
        vec3 specular = specularStrength * spec * lights[i].color * specularColor;
        
        // Combine and apply light intensity
        result += (ambient + diffuse + specular) * lights[i].intensity;
    }

    FragColor = vec4(result, 1.0);
}`