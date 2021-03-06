const vec3 dtt = vec3(65536.0,255.0,1.0);

uniform highp vec2 texture_size;
uniform sampler2D decal;
varying highp vec2 texCoord;

int GET_RESULT(float A, float B, float C, float D)
{
    int x = 0; int y = 0; int r = 0;
    if (A == C) x+=1; else if (B == C) y+=1;
    if (A == D) x+=1; else if (B == D) y+=1;
    if (x <= 1) r+=1;
    if (y <= 1) r-=1;
    return r;
}

float reduce(vec3 color)
{
    return dot(color, dtt);
}

void main()
{
    
    // get texel size
    vec2 ps = vec2(0.999/texture_size.x, 0.999/texture_size.y);
    // calculating offsets, coordinates
    vec2 dx = vec2( ps.x, 0.0);
    vec2 dy = vec2( 0.0, ps.y);
    vec2 g1 = vec2( ps.x,ps.y);
    vec2 g2 = vec2(-ps.x,ps.y);
    vec2 pixcoord = texCoord/ps;
    vec2 fp = fract(pixcoord);
    vec2 pC4 = texCoord-fp*ps;
    vec2 pC8 = pC4+g1;
    // Reading the texels
    vec3 C0 = texture2D(decal,pC4-g1).xyz;
    vec3 C1 = texture2D(decal,pC4-dy).xyz;
    vec3 C2 = texture2D(decal,pC4-g2).xyz;
    vec3 D3 = texture2D(decal,pC4-g2+dx).xyz;
    vec3 C3 = texture2D(decal,pC4-dx).xyz;
    vec3 C4 = texture2D(decal,pC4 ).xyz;
    vec3 C5 = texture2D(decal,pC4+dx).xyz;
    vec3 D4 = texture2D(decal,pC8-g2).xyz;
    vec3 C6 = texture2D(decal,pC4+g2).xyz;
    vec3 C7 = texture2D(decal,pC4+dy).xyz;
    vec3 C8 = texture2D(decal,pC4+g1).xyz;
    vec3 D5 = texture2D(decal,pC8+dx).xyz;
    vec3 D0 = texture2D(decal,pC4+g2+dy).xyz;
    vec3 D1 = texture2D(decal,pC8+g2).xyz;
    vec3 D2 = texture2D(decal,pC8+dy).xyz;
    vec3 D6 = texture2D(decal,pC8+g1).xyz;
    vec3 p00,p10,p01,p11;
    // reducing vec3 to float
    float c0 = reduce(C0);float c1 = reduce(C1);
    float c2 = reduce(C2);float c3 = reduce(C3);
    float c4 = reduce(C4);float c5 = reduce(C5);
    float c6 = reduce(C6);float c7 = reduce(C7);
    float c8 = reduce(C8);float d0 = reduce(D0);
    float d1 = reduce(D1);float d2 = reduce(D2);
    float d3 = reduce(D3);float d4 = reduce(D4);
    float d5 = reduce(D5);float d6 = reduce(D6);
    
    if (c7 == c5 && c4 != c8) {
        p11 = p01 = C7;
    } else if (c4 == c8 && c7 != c5) {
        p11 = p01 = C4;
    } else if (c4 == c8 && c7 == c5) {
        int r = 0;
        r += GET_RESULT(c5,c4,c6,d1);
        r += GET_RESULT(c5,c4,c3,c1);
        r += GET_RESULT(c5,c4,d2,d5);
        r += GET_RESULT(c5,c4,c2,d4);
        if (r > 0)
            p11 = p01 = C5;
        else if (r < 0)
            p11 = p01 = C4;
        else {
            p11 = p01 = 0.5*(C4+C5);
        }
    } else {
        if (c5 == c8 && c8 == d1 && c7 != d2 && c8 != d0)
            p11 = 0.25*(3.0*C8+C7);
        else if (c4 == c7 && c7 == d2 && d1 != c8 && c7 != d6)
            p11 = 0.25*(3.0*C7+C8);
        else
            p11 = 0.5*(C7+C8);
        if (c5 == c8 && c5 == c1 && c4 != c2 && c5 != c0)
            p01 = 0.25*(3.0*C5+C4);
        else if (c4 == c7 && c4 == c2 && c1 != c5 && c4 != d3)
            p01 = 0.25*(3.0*C4+C5);
        else
            p01 = 0.5*(C4+C5);
    }
    if (c4 == c8 && c7 != c5 && c3 == c4 && c4 != d2)
        p10 = 0.5*(C7+C4);
    else if (c4 == c6 && c5 == c4 && c3 != c7 && c4 != d0)
        p10 = 0.5*(C7+C4);
    else
        p10 = C7;
    if (c7 == c5 && c4 != c8 && c6 == c7 && c7 != c2)
        p00 = 0.5*(C7+C4);
    else if (c3 == c7 && c8 == c7 && c6 != c4 && c7 != c0)
        p00 = 0.5*(C7+C4);
    else
        p00 = C4;
    // Distributing the four products
    if (fp.x < 0.50)
    { if (fp.y < 0.50) p10 = p00;}
    else
    { if (fp.y < 0.50) p10 = p01; else p10 = p11;}
    // OUTPUT
    gl_FragColor = vec4(p10, 1);
}
