#version 150

const vec3 ROTATION_AXIS = normalize(vec3(1));
const float ROTATION_SPEED = 500.0;
const float EPSILON = 0.001;
const float MOON_SIZE = 5;
const float SUN_SIZE = 9;

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float GameTime;

in vec2 texCoord0;
in vec3 rayDir;
in float id;

out vec4 fragColor;

// http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
mat3 rotationMatrix(vec3 axis, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    float _c = 1.0 - c;
    
    return mat3(_c * axis.x * axis.x + c,           _c * axis.x * axis.y - axis.z * s,  _c * axis.z * axis.x + axis.y * s,
                _c * axis.x * axis.y + axis.z * s,  _c * axis.y * axis.y + c,           _c * axis.y * axis.z - axis.x * s,
                _c * axis.z * axis.x - axis.y * s,  _c * axis.y * axis.z + axis.x * s,  _c * axis.z * axis.z + c         );
}

// from https://iquilezles.org/www/articles/intersectors/intersectors.htm
vec2 boxIntersection(in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal) {
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if(tN > tF || tF < 0.0) 
        return vec2(-1.0);

    outNormal = -sign(rd) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    return vec2(tN, tF);
}

void main() {
    if (id > 0.5) {
        float size = SUN_SIZE;
        if (id > 1.5)
            size = MOON_SIZE;

        mat3 rotation = rotationMatrix(ROTATION_AXIS, GameTime * ROTATION_SPEED);
        
        vec3 rd = normalize(rayDir) * rotation;
        vec3 ro = vec3(0, 0, 100) * rotation; // Rotating ray origin in the opposite direction
        vec3 normal;
        float t = boxIntersection(ro, rd, vec3(size), normal).x;

        if (t < 0) {
            ro *= -1;
            t = boxIntersection(ro, rd, vec3(size), normal).x;
        }

        if (t > EPSILON) {
            vec3 hitPoint = ro + rd * t;
            vec2 faceTexCoord;
            if (abs(dot(normal, vec3(1, 0, 0))) > 1.0 - EPSILON) {
                faceTexCoord = hitPoint.zy;
            } else if (abs(dot(normal, vec3(0, 1, 0))) > 1.0 - EPSILON) {
                faceTexCoord = hitPoint.xz;
            } else if (abs(dot(normal, vec3(0, 0, 1))) > 1.0 - EPSILON) {
                faceTexCoord = hitPoint.xy;
            }
            faceTexCoord = faceTexCoord / size / 8 - 0.5;
            if (id > 1.5) {
                vec2 phaseTexCoord = floor(texCoord0 * vec2(4, 2));
                float facing = dot(normal, vec3(1, 0, 0));
                if ((texCoord0.x > 0.25)) {
                    if (facing > 1.0 - EPSILON) {
                        if (texCoord0.y > 0.5) {
                            phaseTexCoord = vec2(0, 0);
                        } else {
                            phaseTexCoord = vec2(0, 1);
                        }
                    } else if (facing < -1.0 + EPSILON) {
                        if (texCoord0.y > 0.5) {
                            phaseTexCoord = vec2(0, 1);
                        } else {
                            phaseTexCoord = vec2(0, 0);
                        }
                    }
                }
                faceTexCoord = faceTexCoord;
                faceTexCoord = (phaseTexCoord + faceTexCoord + 1) / vec2(4, 2);
            }
            fragColor = texture(Sampler0, faceTexCoord) * ColorModulator;
        } else {
            discard;
        }
    } else {
        vec4 color = texture(Sampler0, texCoord0);
        if (color.a == 0.0) {
            discard;
        }
        fragColor = color * ColorModulator;
    }
    
}
