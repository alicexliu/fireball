#version 300 es

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform float u_Time;
uniform highp int u_Octaves;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// Hash function for noise
float hash(float p) { 
    p = fract(p * 0.011); p *= p + 7.5; p *= p + p; return fract(p); 
}

// Base noise in 3D
float noise(vec3 x) {
    const vec3 step = vec3(110.0, 241.0, 171.0);
    vec3 i = floor(x);
    vec3 f = fract(x);

    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(
mix(hash(n + dot(step, vec3(0.0, 0.0, 0.0))),
                hash(n + dot(step, vec3(1.0, 0.0, 0.0))), u.x),
            mix(hash(n + dot(step, vec3(0.0, 1.0, 0.0))),
                hash(n + dot(step, vec3(1.0, 1.0, 0.0))), u.x), u.y),
        mix(mix(hash(n + dot(step, vec3(0.0, 0.0, 1.0))),
                hash(n + dot(step, vec3(1.0, 0.0, 1.0))), u.x),
            mix(hash(n + dot(step, vec3(0.0, 1.0, 1.0))),
                hash(n + dot(step, vec3(1.0, 1.0, 1.0))), u.x), u.y),
        u.z
    );
}

// 3D Perlin noise
float PerlinNoise3D(vec3 p) {
    float total = 0.0;
    float persistence = 0.5;

    for (int i = 0; i < u_Octaves; i++) {
        float freq = pow(2.0, float(i));
        float amp  = pow(persistence, float(i));

        total += noise(p * freq) * amp;
    }

    return total;
}

// 3D FBM noise
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    float freqMultiplier = 6.0;
    float ampMultiplier = 0.2;

    for (int i = 0; i < u_Octaves; i++) { 
        value += amplitude * noise(p * frequency);
        frequency *= freqMultiplier;   
        amplitude *= ampMultiplier; 
    }
    return value;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    // low-frequency, high-amplitude displacement
    modelposition.x += sin((u_Time / 60.0 + (modelposition.y + modelposition.z) * 30.0)) * 0.01;
    modelposition.z += cos((u_Time / 40.0 + (modelposition.y) * 50.0)) * 0.0125;

    // higher-frequency, lower-amplitude layer of fbm
    float influence = smoothstep(0.2, 0.5, (modelposition.y + 1.0) / 2.0);
    float offset = fbm(vec3(vs_Pos.xyz) + (u_Time) / 200.0) * 1.25;
    modelposition.y += influence * offset;

    // scale down x and z as y position increases
    float scale = 1.2 - smoothstep(0.2, 1.0, (modelposition.y + 1.0) / 2.0) * 0.25;
    modelposition.x *= scale;
    modelposition.z *= scale;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
