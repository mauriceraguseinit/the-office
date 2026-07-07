#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec2 uOffset;
uniform vec2 uLightPos;
uniform vec4 uLightColor;
uniform float uAmbient;
uniform vec4 uSrcRect;
uniform sampler2D uTexture;
uniform sampler2D uNormalMap;

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 localCoord = fragCoord - uOffset;
    vec2 localUV = localCoord / uSize;

    vec2 sheetUV = mix(uSrcRect.xy, uSrcRect.zw, localUV);
    vec4 texColor = texture(uTexture, sheetUV);

    if (texColor.a < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 normal = normalize(texture(uNormalMap, sheetUV).rgb * 2.0 - 1.0);

    vec3 lightVector = vec3(uLightPos - localCoord, 35.0);
    float distance = length(lightVector);
    vec3 lightDir = normalize(lightVector);

    float diff = max(dot(normal, lightDir), 0.0);
    float attenuation = 150.0 / (distance + 75.0);

    vec3 lightEffect = uLightColor.rgb * diff * attenuation * uLightColor.a;
    vec3 ambientEffect = vec3(uAmbient);

    fragColor = vec4(texColor.rgb * (lightEffect + ambientEffect), texColor.a);
}
