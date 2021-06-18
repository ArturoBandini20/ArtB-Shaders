/*********************************************************************************************************\
*                                                                                                         *
*   ArtB. Splitter                                                                                        *
*   v1.00, 2020 by ArturoBandini                                                                          *
*                                                                                                         *
*   This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License     *
*   To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/                  *
*                                                                                                         *
\*********************************************************************************************************/								

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


/*********************************************************************************************************/
/**** UI Parameters **************************************************************************************/
/*********************************************************************************************************/

uniform int SplitScreen <
	ui_label = "Splitscreen";
	ui_tooltip = "Enable splitscreen functions";
	ui_type = "combo";
	ui_items = " No splitscreen\0 Split horizontal\0 Split vertical\0";
	ui_category = "Splitscreen"; ui_spacing = 2;
> = 0;

uniform bool SplitShow <
	ui_label = "Show split position";
	ui_category = "Splitscreen";
> = false;

uniform bool SplitSwap <
	ui_label = "Swap Splitscreen Layers";
	ui_category = "Splitscreen";
> = false;

uniform float SplitPos < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Split position";
	ui_tooltip = "Define split position";
	ui_min = -1.0; ui_max = 2.0;
	ui_category = "Splitscreen";
> = 0.5;

uniform float S1_Zoom < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: Zoom factor";
	ui_tooltip = "Zoom factor";
	ui_min = 0.1; ui_max = 4.0;
	ui_category = "Splitscreen"; ui_spacing = 1;
> = 1.0;

uniform float S1_XOff < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: X Position";
	ui_tooltip = "X position (X Offset)";
	ui_min = -4.0; ui_max = 4.0;
	ui_category = "Splitscreen";
> = 0.0;

uniform float S1_YOff < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: Y Position";
	ui_tooltip = "Y position (Y Offset)";
	ui_min = -2.0; ui_max = 2.0;
	ui_category = "Splitscreen";
> = 0.0;

uniform float3 S1_BGcolor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Screen #1: Background Color";
	ui_tooltip = "Define background color";
	ui_category = "Splitscreen";
> = float3(0.0, 0.0, 0.0);

uniform float S1_BGalpha < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: Background Transparency";
	ui_tooltip = "Alpha transparency for selected background color";
	ui_min = -0.01; ui_max = 1.0; ui_step = 0.01;
	ui_category = "Splitscreen";
> = -0.1;

uniform float S1_Alpha < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: Alpha Transparency";
	ui_tooltip = "Alpha transparency";
	ui_min = 0.0; ui_max = 1.0;
	ui_category = "Splitscreen";
> = 1.0;

uniform float S2_Zoom < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #2: Zoom factor";
	ui_tooltip = "Zoom factor";
	ui_min = 0.1; ui_max = 4.0;
	ui_category = "Splitscreen"; ui_spacing = 1;
> = 1.0;

uniform float S2_XOff < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #2: X Position";
	ui_tooltip = "X position (X Offset)";
	ui_min = -4.0; ui_max = 4.0;
	ui_category = "Splitscreen";
> = 0.0;

uniform float S2_YOff < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #2: Y Position";
	ui_tooltip = "Y position (Y Offset)";
	ui_min = -2.0; ui_max = 2.0;
	ui_category = "Splitscreen";
> = 0.0;

uniform float3 S2_BGcolor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Screen #2: Background Color";
	ui_tooltip = "Define background color";
	ui_category = "Splitscreen";
> = float3(0.0, 0.0, 0.0);

uniform float S2_BGalpha < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #2: Background Transparency";
	ui_tooltip = "Alpha transparency for selected background color";
	ui_min = -0.01; ui_max = 1.0; ui_step = 0.01;
	ui_category = "Splitscreen";
> = -0.01;

uniform float S2_Alpha < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Screen #1: Alpha Transparency";
	ui_tooltip = "Alpha transparency";
	ui_min = 0.0; ui_max = 1.0;
	ui_category = "Splitscreen";
> = 1.0;

uniform int BorderType <
	ui_label = "Border Type";
	ui_tooltip = "Border Type";
	ui_type = "combo";
	ui_items = " No Border\0 Screen #1: Solid\0 Screen #1: Transparent\0 Screen #2: Solid\0 Screen #2: Transparent\0";
	ui_category = "Border"; ui_spacing = 2;
> = 0;

uniform float3 BorderColor < __UNIFORM_COLOR_FLOAT3
	ui_label = "Border Color";
	ui_tooltip = "Define border color";
	ui_category = "Border";
> = float3(1.0, 1.0, 1.0);

uniform float BorderSize < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Border Size";
	ui_tooltip = "Size of surrounding border";
	ui_min = 0.0; ui_max = 32.0; ui_step = 1.0;
	ui_category = "Border";
> = 1.0;

uniform float BorderAspect < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Border Aspect Correction";
	ui_tooltip = "Border Aspect Correction";
	ui_min = 0.0; ui_max = 4.0; ui_step = 0.001;
	ui_category = "Border";
> = 1.0;


/*********************************************************************************************************/
/**** Definitions ****************************************************************************************/
/*********************************************************************************************************/

#define Angle Radians/57.29578
#define aspectR float(BUFFER_WIDTH*BUFFER_RCP_HEIGHT)
#define px BUFFER_RCP_WIDTH
#define py BUFFER_RCP_HEIGHT


/*********************************************************************************************************/
/**** Samplers *******************************************************************************************/
/*********************************************************************************************************/

texture Tex_Split1 {Width=BUFFER_WIDTH;Height=BUFFER_HEIGHT;Format=RGBA16F;};
sampler Sampler_Split1 {Texture=Tex_Split1;MinFilter=Linear;MagFilter=Linear;};
texture Tex_Split2 {Width=BUFFER_WIDTH;Height=BUFFER_HEIGHT;Format=RGBA16F;};
sampler Sampler_Split2 {Texture=Tex_Split2;MinFilter=Linear;MagFilter=Linear;};


/*********************************************************************************************************/
/**** Functions ******************************************************************************************/
/*********************************************************************************************************/

bool equal_vec(float3 vec1, float3 vec2, float diff)
{
	if (abs(vec1.r-vec2.r)<=diff)
		if (abs(vec1.g-vec2.g)<=diff)
			if (abs(vec1.b-vec2.b)<=diff)
				return true;
	return false;
}

float4 draw_border(float2 uv, float zoom, int type)
{
	float4 color;
	float xx = (uv.x-0.5)*BorderAspect+0.5;
	float x1 = -px*BorderSize/zoom*BorderAspect;
	float x2 = 1.0 - x1;
	float y1,y2,split,zero;
	
	if (type == 1 || type == 2)
	{
		y1 = -py*BorderSize/zoom;
		y2 = -y1 + SplitPos;
		split = SplitPos;
		zero = 0.0;
	} else {
		y1 = SplitPos - py*BorderSize/zoom;
		y2 = 1.0 + py*BorderSize/zoom;;
		split = 1.0;
		zero = SplitPos;
	}
	if (abs(xx-0.5) <= 0.5 && uv.y >= y1 && uv.y <= zero) color = float4(BorderColor,-(uv.y-y1)/y1);  
	if (abs(xx-0.5) <= 0.5 && uv.y <= y2 && uv.y >= split) color = float4(BorderColor,1.0+(uv.y-split)/y1);
	
	if (xx >= x1 && xx <= 0 && uv.y >= zero && uv.y <= split) color = float4(BorderColor,-(xx-x1)/x1);
	if (xx >= x1 && xx <= 0 && uv.y >= y1 && uv.y <= zero) color = float4(BorderColor,min(-(xx-x1)/x1,-(uv.y-y1)/y1));
	if (xx >= x1 && xx <= 0 && uv.y >= split && uv.y <= y2) color = float4(BorderColor,min(-(xx-x1)/x1,1.0+(uv.y-split)/y1));
	
	if (xx >= 1.0 && xx <= x2 && uv.y >= zero && uv.y <= split) color = float4(BorderColor,-(xx-x2)/(x2-1.0));
	if (xx >= 1.0 && xx <= x2 && uv.y >= y1 && uv.y <= zero) color = float4(BorderColor,min(-(xx-x2)/(x2-1.0),-(uv.y-y1)/y1));
	if (xx >= 1.0 && xx <= x2 && uv.y >= split && uv.y <= y2) color = float4(BorderColor,min(-(xx-x2)/(x2-1.0),1.0+(uv.y-split)/y1));

	if ((type == 1 || type == 3) && color.a > 0.0) color.a = 1.0;
	
	return color;
}


/*********************************************************************************************************/
/**** Render Functions ***********************************************************************************/
/*********************************************************************************************************/

float4 PS_Split_P1(float4 pos : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
	float4 outColor = tex2D(ReShade::BackBuffer, coord);
	coord.x = (coord.x - 0.5)*aspectR + 0.5;

	if (coord.y <= 0 || coord.y >= 1) outColor = 0.0;
	
	if (SplitScreen == 1)
	{
		if (coord.y > SplitPos) outColor = 0.0;
		if ( (SplitShow) && (abs(coord.y - SplitPos) <= 2.0*py) ) outColor.rgb = float3(1.0,1.0,0.0);
	}

	if (SplitScreen == 2)
	{
		if (coord.x > SplitPos) outColor = 0.0;
		if ( (SplitShow) && (abs(coord.x - SplitPos) <= 2.0*px) ) outColor.rgb = float3(1.0,1.0,0.0); 
	}

	return outColor;
}

float4 PS_Split_P2(float4 pos : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
	float4 outColor = tex2D(ReShade::BackBuffer, coord);
	coord.x = (coord.x - 0.5)*aspectR + 0.5;

	if (coord.y <= 0 || coord.y >= 1) outColor = 0.0;	
	
	if (SplitScreen == 1)
	{
		if (coord.y <= SplitPos) outColor = 0.0;
		if ( (SplitShow) && (abs(coord.y - SplitPos) <= 2.0*py) ) outColor.rgb = float3(1.0,1.0,0.0); 
	}
	
	if (SplitScreen == 2)
	{
		if (coord.x <= SplitPos) outColor = 0.0;
		if ( (SplitShow) && (abs(coord.x - SplitPos) <= 2.0*px) ) outColor.rgb = float3(1.0,1.0,0.0); 
	}

	return outColor;
}

float4 PS_Split_P3(float4 pos : SV_Position, float2 coord : TEXCOORD0) : SV_Target
{
	if (SplitScreen)
	{
		float2 s1_coord = (coord - 0.5) / S1_Zoom + 0.5;
		s1_coord.x -= S1_XOff/aspectR;
		s1_coord.y -= S1_YOff;

		float2 s2_coord = (coord - 0.5) / S2_Zoom + 0.5;
		s2_coord.x -= S2_XOff/aspectR;
		s2_coord.y -= S2_YOff;

		float4 color_s1 = tex2D(Sampler_Split1, s1_coord);
		if (equal_vec(color_s1,S1_BGcolor,S1_BGalpha) && color_s1.a!=0.0) color_s1.a = 0.0;
		if (abs(s1_coord.y - 0.5) >= 0.5) color_s1 = 0.0;
		
		if (BorderType == 1 || BorderType == 2) color_s1 += draw_border(s1_coord, S1_Zoom, BorderType);
		
		float4 color_s2 = tex2D(Sampler_Split2, s2_coord);
		if (equal_vec(color_s2,S2_BGcolor,S2_BGalpha) && color_s2.a!=0.0) color_s2.a = 0.0;
		if (abs(s2_coord.y - 0.5) >= 0.5) color_s2 = 0.0;

		if (BorderType == 3 || BorderType == 4) color_s2 += draw_border(s2_coord, S2_Zoom, BorderType);

		float4 outColor;
		if (SplitSwap)	outColor = lerp(color_s1, color_s2, color_s2.a * S2_Alpha); else
						outColor = lerp(color_s2, color_s1, color_s1.a * S1_Alpha);

		return outColor;
	}
	return tex2D(ReShade::BackBuffer, coord);
}


/*********************************************************************************************************/
/**** Render Passes **************************************************************************************/
/*********************************************************************************************************/

technique ArtB_Splitter
<
	ui_label = "ArtB Splitter";
	ui_tooltip = "Resizing and positioning of splitscreen screens";
>
{
	pass // Splitscreen Pass 1
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Split_P1;
		RenderTarget0 = Tex_Split1;
	}
	
	pass // Splitscreen Pass 2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Split_P2;
		RenderTarget0 = Tex_Split2;
	}

	pass // Splitscreen Pass 3
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Split_P3;
	}
}
