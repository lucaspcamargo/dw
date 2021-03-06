varying highp vec2 coord;
uniform lowp float fgScale;
uniform lowp float bgScale;
uniform lowp float displacement;

uniform sampler2D src;
uniform sampler2D refl;
uniform lowp float underwaterMix;
uniform lowp vec4 coloring;
void main() {
    lowp vec4 tex = texture2D(src, (coord-vec2(0.5, 0)) * vec2(mix(bgScale, fgScale, coord.y), 1 ) + vec2(displacement, 0) );
    lowp vec4 reflTex = texture2D(refl, vec2(coord.x, mix(1.0 - coord.y, coord.y, underwaterMix)));
    lowp vec3 color = min( vec3(1.0), max(vec3(0.0), tex.rrr + mix(coloring.rgb, reflTex.rgb, mix(tex.b, tex.g, 0.5 + 0.5 * sin(100.0*displacement)) + 0.4 - 0.3*coord.y)) );
    gl_FragColor = vec4(color, 1.0) * coord.y;
}
