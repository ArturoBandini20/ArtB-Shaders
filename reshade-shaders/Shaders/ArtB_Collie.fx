/*********************************************************************************************************\
*                                                                                                         *
*   ArtB. Collie                                                                                          *
*   v2.00, 2021 by ArturoBandini                                                                          *
*                                                                                                         *
*   This shader uses some functions created by "PD80" under the MIT License.                              *
*   Functions/formulas used: Contrast, Brightness, Saturation, Luminance, Vibrance and Exposure.          *
*   Those functions habe been slightly modified by ArturoBandini.                                         *
*   All other functionality has been created by ArturoBandini.                                            *
*                                                                                                         *
*   MIT License                                                                                           *
*                                                                                                         * 
*   Permission is hereby granted, free of charge, to any person obtaining a copy                          *
*   of this software and associated documentation files (the "Software"), to deal                         *
*   in the Software without restriction, including without limitation the rights                          *
*   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell                             *
*   copies of the Software, and to permit persons to whom the Software is                                 *
*   furnished to do so, subject to the following conditions:                                              *
*                                                                                                         *
*   The above copyright notice and this permission notice shall be included in all                        *
*   copies or substantial portions of the Software.                                                       *
*                                                                                                         *
*   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                            *
*   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                              *
*   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                           *
*   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                                *
*   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                         *
*   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE                         *
*   SOFTWARE.                                                                                             *
*                                                                                                         *
\*********************************************************************************************************/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


/*********************************************************************************************************/
/**** UI Parameters **************************************************************************************/
/*********************************************************************************************************/

uniform float ScreenBrightness < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Brightness";
	ui_tooltip = "Brightness Type 1";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options"; ui_spacing = 2;
> = 0.0;

uniform float ScreenContrast < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Contrast";
	ui_tooltip = "Contrast Type 1";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options";
> = 0.0;

uniform float ScreenFade < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Fade";
	ui_tooltip = "Fade0";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options";
> = 0.0;

uniform float ScreenSaturation < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Saturation";
	ui_tooltip = "Saturation of screen";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options";  ui_spacing = 2;
> = 0.0;

uniform float ScreenLuminance < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Luminance";
	ui_tooltip = "Luminance of screen";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options";
> = 0.0;

uniform float ScreenVibrance < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Vibrance";
	ui_tooltip = "Vibrance of screen";
	ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
	ui_category = "Color Options";
> = 0.0;

uniform float ScreenExposure < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Exposure";
	ui_tooltip = "Exposure of screen";
	ui_min = -4.0; ui_max = 4.0; ui_step = 0.001;
	ui_category = "Color Options";
> = 0.0;

uniform float colorShift < __UNIFORM_SLIDER_FLOAT1
	ui_label = "Color Shift";
	ui_min = -180.0; ui_max = 180.0; ui_step = 1.0;
	ui_category = "Color Options";  ui_spacing = 2;
> = 0.0;

uniform int ColorReduction <
	ui_label = "Color Reduction";
	ui_tooltip = "Reduced number of maximum colors";
	ui_type = "combo";
	ui_items = " All Colors\0 6+2 Base Colors\0 8 Colors\0 16 Colors Pal-1\0 16 Colors Pal-2\0"
				" 16 Colors Pal-3\0 64 Colors\0 256 Colors\0 512 Colors\0"
				" ArtB Palette\0 ArtBPalette T2\0";
	ui_category = "Color Options";
> = 0;

uniform int ColorProfile <
	ui_label = "Color Profile";
	ui_tooltip = "Choose one of the color presets";
	ui_type = "combo";
	ui_items = " Color Profile: Neutral\0 Color Profile: Warm\0 Color Profile: Cold\0"
				" Color Profile: Greyscale\0 Color Profile: Green\0 Color Profile: Amber\0"
				" Color Profile: Blue\0 Color Profile: Slightly Crazy\0 ColorProfile: Overdrive\0"
				" Color Profile: Negative\0 Monochrome\0";
	ui_category = "Color Options";
> = 0;

uniform int MonochromeType <
	ui_label = "Monochrome Type";
	ui_tooltip = "Only applies to greyscale, green or amber profiles";
	ui_type = "combo";
	ui_items = " Neutral\0 RGB Monitor\0 TV Mono\0 Agfa\0 Kodak\0";
	ui_category = "Color Options";
> = 0;

uniform int doDither <
	ui_label = "Enable Dithering";
	ui_tooltip = "Enables Dithering";
	ui_type = "combo";
	ui_items = " No Dithering\0 Amplified Dithering\0 Damped Dithering\0"; 
	ui_category = "Color Options";
> = 0;


/*********************************************************************************************************/
/**** Constants ******************************************************************************************/
/*********************************************************************************************************/

static const float  ditherRes = 1.0;
static const float3 mono[]    = { float3(0.33333,0.33333,0.33333), float3(0.21, 0.72, 0.07), float3(0.12, 0.72, 0.05), float3(0.18, 0.41, 0.41), float3(0.24, 0.37, 0.39) };
static const float3 palette[] = { float3(1,1,1), float3(1,1,1), float3(3,1,1), float3(1,3,1), float3(1,1,3), float3(3,3,3), float3(6,5,5), float3(7,6,6), float3(7,7,7) };
static const float3 ArtBpal[] = {
								float3(1.0,0.0,0.0), float3(1.0,0.5,0.5), float3(0.0,1.0,0.0),
								float3(0.5,1.0,0.5), float3(0.0,0.0,1.0), float3(0.5,0.5,1.0),
								float3(1.0,1.0,0.0), float3(0.5,0.5,0.0), float3(1.0,0.0,1.0),
								float3(0.5,0.0,0.5), float3(0.0,1.0,1.0), float3(0.0,0.5,0.5),
								float3(1.0,0.5,0.0), float3(1.0,0.0,0.5), float3(0.0,1.0,0.5),
								float3(0.5,1.0,0.0), float3(0.0,0.5,1.0), float3(0.5,0.0,1.0),
								float3(0.7,0.5,0.3), float3(0.6,0.4,0.1), float3(0.5,0.3,0.0),
								float3(.25,.25,.25), float3(0.5,0.5,0.5), float3(.75,.75,.75),				
								float3(1.0,1.0,1.0), float3(0.0,0.0,0.0)
								};
static const float3 ArtBpal2[]= {
								float3(1.0,0.5,0.5), float3(1.0,0.0,0.0), float3(0.5,0.0,0.0),
								float3(0.5,1.0,0.5), float3(0.0,1.0,0.0), float3(0.0,0.5,0.0),
								float3(0.5,0.5,1.0), float3(0.0,0.0,1.0), float3(0.0,0.0,0.5),
								float3(1.0,1.0,0.5), float3(1.0,1.0,0.0), float3(0.5,0.5,0.0),
								float3(1.0,0.5,1.0), float3(1.0,0.0,1.0), float3(0.5,0.0,0.5),
								float3(0.5,1.0,1.0), float3(0.0,1.0,1.0), float3(0.0,0.5,0.5),
								float3(1.0,0.5,0.0), float3(0.7,0.5,0.2), float3(0.5,0.3,0.0),
								float3(.75,.75,.75), float3(0.5,0.5,0.5), float3(.25,.25,.25),
								float3(1.0,1.0,1.0), float3(0.0,0.0,0.0)
								};
static const float  pattern[] = {
								13, 16, 50, 68, 78, 92, 98, 112, 122, 140, 174,
								1,1, 0,
								4,8, 1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,0,0, 0,0,0,0,
								4,4, 1,0,0,0, 0,0,0,0, 0,0,1,0, 0,0,0,0,
								2,4, 1,0, 0,0, 0,1, 0,0,
								3,4, 1,1,0, 0,0,0, 0,1,1, 0,0,0,
								2,2, 1,0, 0,1,
								3,4, 0,0,1, 1,1,1, 1,0,0, 1,1,1,
								2,4, 0,1, 1,1, 1,0, 1,1,
								4,4, 0,1,1,1, 1,1,1,1, 1,1,0,1, 1,1,1,1,
								4,8, 0,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,0,1, 1,1,1,1, 1,1,1,1, 1,1,1,1,
								1,1, 1
								};
								

/*********************************************************************************************************/
/**** Functions ******************************************************************************************/
/*********************************************************************************************************/

float getLum( in float3 x ) { return dot( x, float3( 0.212656, 0.715158, 0.072186 )); }

float3 sl( float3 b) { return b < 0.5f ? ( 2.0f * b * b + b * b * ( 1.0f - 2.0f * b )) :
                      ( sqrt( b ) * ( 2.0f * b - 1.0f ) + 2.0f * b * ( 1.0f - b )); }

float ToSrgb1(float c) { return c<0.0031308 ? c*12.92 : 1.055*pow(abs(c),0.41666)-0.055; }

float3 ToSrgb(float3 c) { return float3(ToSrgb1(c.r),ToSrgb1(c.g),ToSrgb1(c.b)); }					  

float3 dotDither(float3 color, float2 pos, int type, float res)
{
	float maxBright = max(max(color.r, color.g), color.b);
	uint nPattern;
	if (maxBright < 0.01) nPattern = 0; else
		if (maxBright > 0.99) nPattern = 10; else
			nPattern = maxBright < 0.5 ? ceil(maxBright * 10.0) : floor(maxBright * 10.0);
	
	uint px			= floor(pos.x * BUFFER_WIDTH / res);
	uint py			= floor(pos.y * BUFFER_HEIGHT / res);
	uint posStart	= pattern[nPattern];
	uint posColumns	= pattern[posStart - 2];
	uint posLines	= pattern[posStart - 1];

	uint posX		= px % posColumns;
	uint posY		= py % posLines;
	
	uint posValue	= pattern[posStart + posX + posColumns * posY];	

	maxBright 		= (type == 1) ? maxBright : 1.0;
	if (maxBright > 0.0) color = float(posValue) * color / maxBright;
	
	return color;
}


/*********************************************************************************************************/
/**** Render Functions ***********************************************************************************/
/*********************************************************************************************************/

float4 PS_Collie(float4 pos : SV_Position, float2 coord : TEXCOORD) : SV_Target
{
	float4 outColor = tex2D(ReShade::BackBuffer, coord);

	// Dithering
	if (doDither) outColor.rgb = dotDither(outColor.rgb, coord, doDither, ditherRes);


	// Apply reduced color palette
	if (ColorReduction)
	{
		float3 cPal = palette[ColorReduction - 1];
		if (ColorReduction > 1)
		{
			if (ColorReduction < 9) outColor.rgb = round (outColor.rgb * cPal) / cPal; else
				{
					float best_val = 1.0;
					uint  best_pal = 0;
					float temp;					
					for (int i = 0; i < 26; ++i)
					{
						temp = ColorReduction == 9 ? distance(outColor.rgb, ArtBpal[i]) : distance(outColor.rgb, ArtBpal2[i]);
						if (temp < best_val)
						{
							best_val = temp;
							best_pal = i;
						}
					}
					outColor.rgb = ColorReduction == 9 ? ArtBpal[best_pal] * outColor.a : ArtBpal2[best_pal] * outColor.a;
				}
		} else {
			float temp = max(max(outColor.r, outColor.g), outColor.b);
			if (temp > 0.0) outColor.rgb = float3(floor(outColor.r/temp),floor(outColor.g/temp),floor(outColor.b/temp));
		}
	}

	
	// Apply color profile
	switch(ColorProfile)
	{
		case 0 : break;
		case 1 : outColor.rgb *= float3(1.1, 1.0, 0.8); break;
		case 2 : outColor.rgb *= float3(0.8, 1.0, 1.1); break;
		case 3 : outColor.rgb  = lerp(dot(mono[MonochromeType], outColor.rgb), outColor.rgb, 0.0); break;
		case 4 : outColor.rgb  = lerp(dot(mono[MonochromeType], outColor.rgb), outColor.rgb, 0.0);
				 outColor.rgb  = float3(0.0, 1.2 * outColor.g, 0.0); break;
		case 5 : outColor.rgb  = lerp(dot(mono[MonochromeType], outColor.rgb), outColor.rgb, 0.0);
				 outColor.rgb  = float3(1.2 * outColor.r, 0.8 * outColor.g, 0.0); break;
		case 6 : outColor.rgb  = lerp(dot(mono[MonochromeType], outColor.rgb), outColor.rgb, 0.0);
				 outColor.rgb  = float3(0.7 * outColor.r, 0.7 * outColor.g, 1.2 * outColor.b); break;		 
		case 7 : outColor.rgb  = float3(outColor.r, 0.4 * outColor.r + 0.6 * outColor.g, outColor.b - 0.2 * outColor.r); break;
		case 8 : outColor.rgb  = ToSrgb(outColor.rgb) * 0.8; break;
		case 9 : outColor.rgb  = float3(1.0 - outColor.r, 1.0 - outColor.g, 1.0 - outColor.b) * outColor.a; break;
		case 10: outColor.rgb  = lerp(dot(mono[MonochromeType], outColor.rgb), outColor.rgb, 0.0);
				 outColor.rgb  = outColor.r > (float(colorShift / 360) + 0.5) ? outColor.rgb = float3(1.0, 1.0, 1.0) : outColor.rgb = 0.0; break;
	}
	
	// Apply Saturation
	if( ScreenSaturation ) outColor.rgb = lerp( getLum( outColor.rgb), outColor.rgb, ScreenSaturation + 1.0 );
	
	// Apply Luminance
	if( ScreenLuminance ) outColor.rgb = lerp( outColor.rgb, 1.0 - pow( 1.0 - outColor.rgb, 2.0 ), 2.0 * ScreenLuminance );
	
	// Apply Brightness
	if( ScreenBrightness ) outColor.rgb *= (1.0 + ScreenBrightness);
	
	// Apply Contrast
	if( ScreenContrast ) outColor.rgb = lerp( outColor.rgb, sl(outColor.rgb), 2.0 * ScreenContrast );

	// Apply Fade
	if( ScreenFade ) if (distance(outColor.rgb,float3(0.0,0.0,0.0)) > 0.0) outColor.rgb = lerp( outColor.rgb, float3(0.5,0.5,0.5), ScreenFade );

	//Apply Vibrance
	if( ScreenVibrance )
	{
		float4 sat = 0.0f;
		sat.rg = float2( min( min( outColor.r, outColor.g ), outColor.b ), max( max( outColor.r, outColor.g ), outColor.b ));
		sat.b = sat.g - sat.r;
		sat.a = getLum( sat.rgb );
		outColor.rgb = lerp( sat.a, outColor.rgb, 1.0f + ( ScreenVibrance * ( 1.0f - sat.a )));	
	}
	
	//Apply Exposure
	if( ScreenExposure ) outColor.rgb = saturate( outColor.rgb * ( ScreenExposure * ( 1.0 - outColor.rgb ) + 1.0 ));

	//Apply Color Shift
	if (colorShift)
	{
		float shift = colorShift / 120.0;
		float3 OC = outColor.rgb;
		if (shift > 0.0 && shift <= 1.0)	outColor.rgb = float3((1-shift)*OC.r+shift*OC.g     , (1-shift)*OC.g+shift*OC.b     , (1-shift)*OC.b+shift*OC.r);     else
						if (shift > 1.0)	outColor.rgb = float3((2-shift)*OC.g+(shift-1)*OC.b , (2-shift)*OC.b+(shift-1)*OC.r , (2-shift)*OC.r+(shift-1)*OC.g); else	
		if (shift >=-1.0 && shift < 0.0)	outColor.rgb = float3((1+shift)*OC.r-shift*OC.b     , (1+shift)*OC.g-shift*OC.r     , (1+shift)*OC.b-shift*OC.g);     else
											outColor.rgb = float3((2+shift)*OC.b-(shift+1)*OC.g , (2+shift)*OC.r-(shift+1)*OC.b , (2+shift)*OC.g-(shift+1)*OC.r);
	}

	return outColor;
}


/*********************************************************************************************************/
/**** Render Passes **************************************************************************************/
/*********************************************************************************************************/

technique ArtB_Collie
<
	ui_label = "ArtB Collie";
	ui_tooltip = "Adjust Colors";
>
{
	pass // Collie
	{	VertexShader  = PostProcessVS;
		PixelShader   = PS_Collie; }
}
