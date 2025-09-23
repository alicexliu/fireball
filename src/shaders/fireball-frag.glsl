#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform highp int u_Octaves;
uniform vec4 u_GradColor;
uniform float u_Amplitude;

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
    float amplitude = u_Amplitude;
    float frequency = 1.0;

    for (int i = 0; i < u_Octaves; i++) { 
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;   
        amplitude *= 0.5; 
    }
    return value;
}

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5f));
}

void main()
{
        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;
        float lightIntensity = diffuseTerm + ambientTerm;

        // Gradient color
        // Lerp between the base and gradient color
        float heightFactor = clamp((fs_Nor.y + 1.0) * 0.55, 0.0, 1.0);
        vec4 baseColor = u_Color;
        vec4 gradColor = u_GradColor; 
        vec3 fireColor = mix(vec3(gradColor), vec3(baseColor), heightFactor);

        // Lighter gradient color using perlin noise
        vec3 lighter = gradColor.xyz + vec3(0.37);
        float heightFactor1 = smoothstep(-1.0, -0.5, fs_Pos.y);
        float noise = PerlinNoise3D(fs_Pos.xyz * 7.0 + vec3(0.0, u_Time / 50.0, 0.0));
        noise = bias(noise, 0.7);
        noise = pow(noise, 1.3) * 1.25;

        float cutoff = -1.5;
        float blendWidth = 0.1;  

        float edge = smoothstep(cutoff + noise * 0.75 - blendWidth,
                                cutoff + noise * 0.75 + blendWidth,
                                fs_Pos.y);
        fireColor = mix(lighter, fireColor, edge);

        // Compute final color
        out_Col = vec4(fireColor.rgb, baseColor.a);
}
