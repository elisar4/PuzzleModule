//  TestShader.swift
//  Created by Vladimir Roganov on 17.12.2019.

import SpriteKit

class TestShader {
    
    static private var shader: SKShader!
    
    static private let shaderString =
"""
void main() {
    float r = min(u_sprite_size.x, u_sprite_size.y);

    float div = 1.0;

    vec2 uv = u_sprite_size / r;
    uv.x /= div;
    uv.y = 1.0 - uv.y;
    
    vec3 c = texture2D(u_texture, uv).rgb;

    float a = texture2D(u_texture, uv).a;
    bool i = bool(step(0.5, a) == 1.0);

    const int md = 20;
    const int h_md = md / 2;

    float d = float(md);

    for (int x = -h_md; x != h_md; ++x) {
        for (int y = -h_md; y != h_md; ++y) {
            vec2 o = vec2(float(x), float(y));
            vec2 s = (v_tex_coord + o) / r;
            s.x /= div;
            s.y = 1.0 - s.y;
            
            float o_a = texture2D(u_texture, s).a;
            bool o_i = bool(step(0.5, o_a) == 1.0);
            
            if (!i && o_i || i && !o_i)
                d = min(d, length(o));
        }
    }

    d = clamp(d, 0.0, float(md)) / float(md);

    if (i)
        d = -d;

    d = d * 0.5 + 0.5;
    d = 1.0 - d;


    float border_fade_outer = 0.1;
    float border_fade_inner = 0.01;
    float border_width = 0.25;
    vec3 border_color = vec3(1.0, 1.0, 1.0);

    float outer = smoothstep(0.5 - (border_width + border_fade_outer), 0.5, d);

    vec3 temp = vec3(0.0, 0.0, 0.0);
    vec4 border = mix(vec4(temp, 0.0), vec4(border_color, 1.0), outer);

    float inner = smoothstep(0.5, 0.5 + border_fade_inner, d);

    vec4 color = mix(border, vec4(c, 1.0), inner);

    gl_FragColor = texture2D(u_texture, v_tex_coord) * v_color_mix.a;//vec4(c, 1.0);//vec4(border_color, 1);

//    vec4 current_color = SKDefaultShading();
//    if (current_color.a > 0.1) {
//        // Normalized pixel coordinates (from 0 to 1)
//        vec2 uv = gl_FragCoord.xy/a_size;
//
//        // Time varying pixel color
//        vec3 col = 0.5 + 0.5*cos(u_time+uv.xyx+vec3(0,2,4));
//
//        // Output to screen
//        gl_FragColor = vec4(col,1.0);
//    } else {
//       // use the current (transparent) color
//       gl_FragColor = current_color;
//   }
}
"""
    
    class func shared() -> SKShader {
        if shader == nil {
            shader = SKShader(source: shaderString, uniforms: [])
            if #available(iOS 9.0, *) {
                shader.attributes = [SKAttribute(name: "a_size", type: .vectorFloat2)]
            }
        }
        return shader
    }
}
