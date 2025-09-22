#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

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

const int OCTAVES = 7;
// 3D Perlin-style noise
float PerlinNoise3D(vec3 p) {
    float total = 0.0;
    float persistence = 0.5;

    for (int i = 0; i < OCTAVES; i++) {
        float freq = pow(2.0, float(i));
        float amp  = pow(persistence, float(i));

        total += noise(p * freq) * amp;
    }

    return total;
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        diffuseColor.rgb = diffuseColor.rgb * 0.5 + vec3(PerlinNoise3D(vec3(fs_Pos) * sin(u_Time / 300.0) * 2.0) * 0.5);

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
