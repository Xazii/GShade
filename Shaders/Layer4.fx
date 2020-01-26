/*------------------.
| :: Description :: |
'-------------------/

    Layer (version 0.3)

    Author: CeeJay.dk
    License: MIT

    About:
    Blends an image with the game.
    The idea is to give users with graphics skills the ability to create effects using a layer just like in an image editor.
    Maybe they could use this to create custom CRT effects, custom vignettes, logos, custom hud elements, toggable help screens and crafting tables or something I haven't thought of.

    Ideas for future improvement:
    * More blend modes
    * Texture size, placement and tiling control
    * A default Layer texture with something useful in it

    History:
    (*) Feature (+) Improvement (x) Bugfix (-) Information (!) Compatibility
    
    Version 0.2 by seri14 & Marot Satil
    * Added the ability to scale and move the layer around on an x, y axis.

    Version 0.3 by seri14
    * Reduced the problem of layer color is blending with border color
*/

#include "ReShade.fxh"

#ifndef Layer4Tex
#define Layer4Tex "Layer4.png" // Add your own image file to \reshade-shaders\Textures\ and provide the new file name in quotes to change the image displayed!
#endif
#ifndef LAYER4_SIZE_X
#define LAYER4_SIZE_X BUFFER_WIDTH
#endif
#ifndef LAYER4_SIZE_Y
#define LAYER4_SIZE_Y BUFFER_HEIGHT
#endif

#if LAYER4_SINGLECHANNEL
#define TEXFORMAT R8
#else
#define TEXFORMAT RGBA8
#endif

uniform float Layer4_Blend <
    ui_label = "Opacity";
    ui_tooltip = "The transparency of the layer.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 1.0;

uniform float Layer4_Scale <
  ui_type = "slider";
    ui_label = "Scale";
    ui_min = 0.01; ui_max = 5.0;
    ui_step = 0.001;
> = 1.001;

uniform float Layer4_PosX <
  ui_type = "slider";
    ui_label = "Position X";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

uniform float Layer4_PosY <
  ui_type = "slider";
    ui_label = "Position Y";
    ui_min = -2.0; ui_max = 2.0;
    ui_step = 0.001;
> = 0.5;

texture Layer4_Texture <source=Layer4Tex;> { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format=RGBA8; };
sampler Layer4_Sampler { Texture = Layer4_Texture; };

#define _layer4Coord(_) (_ / (float2(LAYER4_SIZE_X, LAYER4_SIZE_Y) * Layer4_Scale / BUFFER_SCREEN_SIZE))

void PS_Layer4(in float4 pos : SV_Position, float2 texCoord : TEXCOORD, out float4 passColor : SV_Target) {
	const float4 backColor = tex2D(ReShade::BackBuffer, texCoord);
	const float2 pickCoord = _layer4Coord(texCoord) + float2(Layer4_PosX, Layer4_PosY) * (1.0 - _layer4Coord(1.0));

	passColor = tex2D(Layer4_Sampler, pickCoord) * all(pickCoord == saturate(pickCoord));
	passColor = lerp(backColor, passColor, passColor.a * Layer4_Blend);
	passColor.a = backColor.a;
}

technique Layer4 {
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_Layer4;
    }
}