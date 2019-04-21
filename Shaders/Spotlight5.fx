/*
	Spotlight shader based on the Flashlight shader by luluco250

	MIT Licensed.
*/

#include "ReShade.fxh"

#ifndef FLASHLIGHT_NO_BLEND_FIX
#define FLASHLIGHT_NO_BLEND_FIX 0
#endif
uniform float u5XCenter <
  ui_label = "X Position";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "X coordinate of beam center. Axes start from upper left screen corner.";
> = 1.0;

uniform float u5YCenter <
  ui_label = "Y Position";
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.0;
	ui_tooltip = "Y coordinate of beam center. Axes start from upper left screen corner.";
> = 1.0;

uniform float u5Brightness <
	ui_label = "Brightness";
	ui_tooltip =
		"Flashlight halo brightness.\n"
		"\nDefault: 10.0";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 100.0;
	ui_step = 0.01;
> = 10.0;

uniform float u5Size <
	ui_label = "Size";
	ui_tooltip =
		"Flashlight halo size in pixels.\n"
		"\nDefault: 420.0";
	ui_type = "slider";
	ui_min = 10.0;
	ui_max = 1000.0;
	ui_step = 1.0;
> = 420.0;

uniform float3 u5Color <
	ui_label = "Color";
	ui_tooltip =
		"Flashlight halo color.\n"
		"\nDefault: R:255 G:230 B:200";
	ui_type = "color";
> = float3(255, 230, 200) / 255.0;

uniform float u5Distance <
	ui_label = "Distance";
	ui_tooltip =
		"The distance that the flashlight can illuminate.\n"
		"Only works if the game has depth buffer access.\n"
		"\nDefault: 0.1";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.001;
> = 0.1;

uniform bool u5ToggleTexture <
	ui_label = "Toggle Texture";
	ui_tooltip = "Enable or disable the flashlight texture.";
> = 1;

uniform bool u5ToggleDepth <
	ui_label = "Toggle Depth";
	ui_tooltip = "Enable or disable depth.";
> = 1;

sampler2D s5Color {
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
	MinFilter = POINT;
	MagFilter = POINT;
};

#define nsin(x) (sin(x) * 0.5 + 0.5)

float4 PS_5Flashlight(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET {
	const float2 res = ReShade::ScreenSize;
	const float2 uCenter = float2(2 - u5XCenter, u5YCenter);
	float2 coord = uv * res * uCenter;

	float halo = distance(coord, res * 0.5);
	float flashlight = u5Size - min(halo, u5Size);
	flashlight /= u5Size;
	
	// Add some texture to the halo by using some sin lines + reduce intensity
	// when nearing the center of the halo.
	if (u5ToggleTexture == 0)
	{
		float defects = sin(flashlight * 30.0) * 0.5 + 0.5;
		defects = lerp(defects, 1.0, flashlight * 2.0);

		static const float contrast = 0.125;

		defects = 0.5 * (1.0 - contrast) + defects * contrast;
		flashlight *= defects * 4.0;
	}
	else
	{
    flashlight *= 2.0;
  }

	if (u5ToggleDepth == 1)
  {
    float depth = 1.0 - ReShade::GetLinearizedDepth(uv);
    depth = pow(abs(depth), 1.0 / u5Distance);
    flashlight *= depth;
  }

	float3 colored_flashlight = flashlight * u5Color;
	colored_flashlight *= colored_flashlight * colored_flashlight;

	float3 result = 1.0 + colored_flashlight * u5Brightness;

	float3 color = tex2D(s5Color, uv).rgb;
	color *= result;

	#if !FLASHLIGHT_NO_BLEND_FIX

	// Add some minimum amount of light to very dark pixels.	
	color = max(color, (result - 1.0) * 0.001);
	
	#endif

	return float4(color, 1.0);
}

technique Spotlight5 {
	pass {
		VertexShader = PostProcessVS;
		PixelShader = PS_5Flashlight;
		SRGBWriteEnable = true;
	}
}
