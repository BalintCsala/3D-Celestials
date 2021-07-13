#version 150

const float SUNDIST = 110.0;

in vec3 Position;
in vec2 UV0;

uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform sampler2D Sampler0;

out vec2 texCoord0;
out vec3 rayDir;
out float id;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord0 = UV0;
    id = 0;

    if (Position.y < SUNDIST && Position.y > -SUNDIST && (ModelViewMat * vec4(Position, 1.0)).z > -SUNDIST) {
        float near = 0.05;
        float far  = ProjMat[3][2] * near / (ProjMat[3][2] + 2.0 * near);
        mat4 projInv = inverse(ProjMat * ModelViewMat);
        
        vec2 pos = texCoord0 - 0.5;

        ivec2 size = textureSize(Sampler0, 0);
        if (size.x == size.y) {
            // Sun
            id = 1;
        } else {
            // Moon
            id = 2;
            pos = fract(texCoord0 * vec2(2, 1)) - 0.25;
        }

        float aspectRatio = 1.0 / ProjMat[0][0] * ProjMat[1][1];
        pos.x /= aspectRatio;

        rayDir = (projInv * vec4(pos * (far - near), far + near, far - near)).xyz;
    }
    
}
