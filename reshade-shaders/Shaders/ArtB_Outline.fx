/*********************************************************************************************************\
*                                                                                                         *
*   ArtB. Outline                                                                                         *
*   v1.00, 2020 by ArturoBandini                                                                          *
*   License: Free for everyone                                                                            *
*                                                                                                         *
\*********************************************************************************************************/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


/*********************************************************************************************************/
/**** UI Parameters **************************************************************************************/
/*********************************************************************************************************/

uniform int outline_mode <
	ui_label = " Outline Mode";
	ui_tooltip = "Choose outline mode";
	ui_type = "combo";
	ui_items = " Classic Outline\0 Filled Outline\0 Special\0";
> = 0;

uniform float3 outline_color < __UNIFORM_COLOR_FLOAT3
	ui_label = " Outline Base Color";
> = float3(0.0, 0.0, 0.0);

uniform int use_thresh_color <
	ui_label = " Color Threshold";
	ui_tooltip = "Choose how to handle color thresholds\n"
				 "You need this to counter bilinear filtering, for example\n"
				 "or if source has too many colors (>16)";
	ui_type = "combo";
	ui_items = " No Color Threshold\0 Overall Color Threshold\0 RGB Color Thresholds\0";
> = 0;

uniform float threshold_Mono < __UNIFORM_SLIDER_FLOAT1
	ui_label = " Monochrome Threshold";
	ui_min = 0.01; ui_max = 1.0; ui_step = 0.01;
> = 0.01;

uniform float threshold_Color < __UNIFORM_SLIDER_FLOAT1
	ui_label = " Threshold: All Colors";
	ui_min = 1.0; ui_max = 20.0; ui_step = 0.01;
	ui_spacing = 2;
> = 2.5;

uniform float threshold_Red < __UNIFORM_SLIDER_FLOAT1
	ui_label = " Threshold: Color Red";
	ui_min = 1.0; ui_max = 20.0; ui_step = 0.01;
	ui_spacing = 2;
> = 2.0;

uniform float threshold_Green < __UNIFORM_SLIDER_FLOAT1
	ui_label = " Threshold: Color Green";
	ui_min = 1.0; ui_max = 20.0; ui_step = 0.01;
> = 1.8;

uniform float threshold_Blue < __UNIFORM_SLIDER_FLOAT1
	ui_label = " Threshold: Color Blue";
	ui_min = 1.0; ui_max = 20.0; ui_step = 0.01;
> = 1.5;

uniform int color_mode <
	ui_label = " Color Mode";
	ui_tooltip = "Choose color, greyscale or monochrome mode";
	ui_type = "combo";
	ui_items = " Colors\0 Greyscale\0 Monochrome\0";
	ui_spacing = 2;
> = 0;

uniform bool inverted <
	ui_label = "Enable Inverted Mode";
> = false;


/*********************************************************************************************************/
/**** Render Functions ***********************************************************************************/
/*********************************************************************************************************/

float4 PS_Outline_P1(float4 pos : SV_Position, float2 coord : TEXCOORD) : SV_Target
{
	// get current sample color
	float4 outColor = tex2D(ReShade::BackBuffer, coord);					

	// get pixel size
	float px = BUFFER_RCP_WIDTH;
	float py = BUFFER_RCP_HEIGHT;

	// define central pixel color and 4 neighbours
	float4 col0 = outColor;
	float4 col1, col2, col3, col4;
	
	// get color of 4 neighbour pixels
	col1 =  tex2D(ReShade::BackBuffer, float2(coord.x - px, coord.y));
	col2 =  tex2D(ReShade::BackBuffer, float2(coord.x + px, coord.y));
	col3 =  tex2D(ReShade::BackBuffer, float2(coord.x, coord.y - py));
	col4 =  tex2D(ReShade::BackBuffer, float2(coord.x, coord.y + py));

	// try to eliminate too many colors
	if (use_thresh_color > 0)
	{
		float d1 = threshold_Color * 0.05;
		float d2 = d1;
		float d3 = d1;
		float t1 = threshold_Color;
		float t2 = t1;
		float t3 = t1;

		if (use_thresh_color == 2)
		{
			d1 = threshold_Red * 0.05;
			d2 = threshold_Green * 0.05;
			d3 = threshold_Blue * 0.05;
			t1 = threshold_Red;
			t2 = threshold_Green;
			t3 = threshold_Blue;
		}				
		
		// number of colors is reduced by truncating
		col0.rgb = float3(floor(t1*col0.r+d1)/t1, floor(t2*col0.g+d2)/t2, floor(t3*col0.b+d3)/t3);
		col1.rgb = float3(floor(t1*col1.r+d1)/t1, floor(t2*col1.g+d2)/t2, floor(t3*col1.b+d3)/t3);
		col2.rgb = float3(floor(t1*col2.r+d1)/t1, floor(t2*col2.g+d2)/t2, floor(t3*col2.b+d3)/t3);
		col3.rgb = float3(floor(t1*col3.r+d1)/t1, floor(t2*col3.g+d2)/t2, floor(t3*col3.b+d3)/t3);
		col4.rgb = float3(floor(t1*col4.r+d1)/t1, floor(t2*col4.g+d2)/t2, floor(t3*col4.b+d3)/t3);
	}
	
	// how many neighbours have the same color?
	int count = 0;
	if (col0.r==col1.r && col0.g==col1.g && col0.b==col1.b) count++;
	if (col0.r==col2.r && col0.g==col2.g && col0.b==col2.b) count++;
	if (col0.r==col3.r && col0.g==col3.g && col0.b==col3.b) count++;
	if (col0.r==col4.r && col0.g==col4.g && col0.b==col4.b) count++;
	
	// type of outline mode. Mode 3 is some kind of color mashing
	switch (outline_mode)
	{
		case 0 : if (count == 4) outColor.rgb = outline_color * outColor.a; break;
		case 1 : if ((count == 3) || (count == 2 &&
										(col1.r!=col2.r && col3.r!=col4.r) ||
										(col1.g!=col2.g && col3.g!=col4.g) ||
										(col1.b!=col2.b && col3.b!=col4.b )))
										outColor.rgb = outline_color; break;
		case 2 : if ((count >= 3) || (count == 2 &&
										(col1.r!=col2.r && col3.r!=col4.r) ||
										(col1.g!=col2.g && col3.g!=col4.g) ||
										(col1.b!=col2.b && col3.b!=col4.b )))
										outColor.rgb = (col0.rgb + col1.rgb + col2.rgb + col3.rgb + col4.rgb)/5; break;
	}
	
	// calculate greyscale and monochrome values
	switch (color_mode)
	{
		case 1 : outColor.rgb = (outColor.r + outColor.g + outColor.b)/3; break;
		case 2 : outColor.rgb = (outColor.r + outColor.g + outColor.b)/3 < threshold_Mono ? 0.0 : 1.0; break;
	}

	// invert colors, depending on color mode
	if (inverted && outColor.a != 0.0)
	{
		if (color_mode == 0) 
		{
			if ((outColor.r + outColor.g + outColor.b) < 0.1) outColor.rgb=float3(1.0,1.0,1.0); else
				if ((outColor.r + outColor.g + outColor.b) > 2.7) outColor.rgb=float3(0.0,0.0,0.0);
		} else outColor.rgb = 1.0 - outColor.rgb;
	}
	
	// done	
	return outColor;
}


/*********************************************************************************************************/
/**** Render Passes **************************************************************************************/
/*********************************************************************************************************/

technique ArtB_Outline
<
	ui_label = "ArtB Outline";
	ui_tooltip = "Draw Outlines";
>
{
	pass // Outline
	{	VertexShader  = PostProcessVS;
		PixelShader   = PS_Outline_P1; }
}
		