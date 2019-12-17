//  TestShader.swift
//  Created by Vladimir Roganov on 17.12.2019.

import SpriteKit

class TestShader {
    
    static private var shader: SKShader!
    
    static private let shaderString =
"""
void main() {
    
    vec4 current_color = SKDefaultShading();

    vec2 diagPP = 1.0 / a_size;
    vec2 diagMP = vec2(-diagPP.x, diagPP.y);
    vec2 diagPM = vec2(diagPP.x, -diagPP.y);
    
    vec4 c3 = texture2D(u_texture, v_tex_coord + diagPP);
    vec4 c7 = texture2D(u_texture, v_tex_coord - diagPP);
    vec4 c1 = texture2D(u_texture, v_tex_coord + diagMP);
    vec4 c9 = texture2D(u_texture, v_tex_coord + diagPM);

    float summ = c3.a + c7.a + c1.a + c9.a;

    if (summ < 3.0 && summ > 1.0) {
        float red = sin(40.*length(v_tex_coord) - u_time*5.)*0.5 + 0.25;
        gl_FragColor = vec4(red,1,0,0.75);
    } else {
        gl_FragColor = current_color;
    }
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
