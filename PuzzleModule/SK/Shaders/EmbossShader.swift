//  EmbossShader.swift
//  Created by Vladimir Roganov on 17.12.2019.

import SpriteKit

class EmbossShader {
    
    static private var shader: SKShader!
    
    static private let shaderString =
"""
void main() {
    // find the current pixel color
    vec4 current_color = SKDefaultShading();

    // if it's not transparent
    if (current_color.a > 0.0) {
        // find the size of one pixel by reading the input size
        vec2 pixel_size = 0.7 / a_size;

        // copy our current color so we can modify it
        vec4 new_color = current_color;

        // move up one pixel diagonally and read the current color,
        // multiply it by the input strength, then add it to our pixel color
        new_color += texture2D(u_texture, v_tex_coord - pixel_size) * u_strength;

        // move down one pixel diagonally and read the current color,
        // multiply it by the input strength, then subtract it to our pixel color
        new_color -= texture2D(u_texture, v_tex_coord + pixel_size) * u_strength;

        // use that new color, with an alpha of 1, for our pixel color, multiplying by this pixel's alpha
        // (to avoid a hard edge) and also multiplying by the alpha for this node
        gl_FragColor = vec4(new_color.rgb, 1) * current_color.a * v_color_mix.a;
    } else {
        // use the current (transparent) color
        gl_FragColor = current_color;
    }
}
"""
    
    class func shared() -> SKShader {
        if shader == nil {
            shader = SKShader(source: shaderString, uniforms: [
                SKUniform(name: "u_strength", float: 0.35)
            ])
            if #available(iOS 9.0, *) {
                shader.attributes = [SKAttribute(name: "a_size", type: .vectorFloat2)]
            }
        }
        return shader
    }
}
