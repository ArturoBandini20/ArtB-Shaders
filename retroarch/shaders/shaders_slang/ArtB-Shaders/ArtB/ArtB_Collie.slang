#version 450

/*********************************************************************************************************\
*                                                                                                         *
*   ArtB. Collie                                                                                         *
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

layout(push_constant) uniform Push
{
	vec4 OutputSize;

	float ScreenBrightness;
	float ScreenContrast;
	float ScreenFade;
	float ScreenSaturation;
	float ScreenLuminance;
	float ScreenVibrance;
	float ScreenExposure;
	float colorShift;
	float ColorReduction;
	float ColorProfile;
	float MonochromeType;
	float doDither;
} params;

#pragma parameter ScreenBrightness	"Brightness"								0.00 -1.00  1.00 0.01
#pragma parameter ScreenContrast	"Contrast"									0.00 -1.00  1.00 0.01
#pragma parameter ScreenFade		"Fade"										0.00 -1.00  1.00 0.01
#pragma parameter ScreenSaturation	"Saturation"								0.00 -1.00  1.00 0.01
#pragma parameter ScreenLuminance	"Luminance"									0.00 -1.00  1.00 0.01
#pragma parameter ScreenVibrance	"Vibrance"									0.00 -1.00  1.00 0.01
#pragma parameter ScreenExposure	"Exposure"									0.00 -4.00  4.00 0.01
#pragma parameter colorShift		"360 Degrees Color Shift"					0.00 -180.0 180.0 1.0
#pragma parameter ColorReduction	"Color All|6+2|8|16(1)|16(2)|16(3)|64|256|512|ArtB-1|ArtB-2"	0.0 0.0 10.0 1.0
#pragma parameter ColorProfile		"Neutral|Warm|Cold|Grey|Green|Amber|Blue|Crazy|Over|Neg|Mono"	0.0 0.0 10.0 1.0
#pragma parameter MonochromeType	"Monochrome Type: Neutral|0  RGB|1  TV|2  Agfa|3  Kodak|4"	0.0 0.0 4.0 1.0
#pragma parameter doDither			"Dithering: 0|None  1|Amplified  2|Damped"	0.00  0.00  2.00 1.00

#define ditherRes 1.0

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in  vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;


vec3 getLum( vec3 x )
{ 
	float dot_val = dot( x, vec3( 0.212656, 0.715158, 0.072186 ) );
	return vec3( dot_val, dot_val, dot_val );
}

vec3 sl( vec3 b )			{ return (b.r < 0.5 && b.g < 0.5 && b.r < 0.5) ? ( 2.0 * b * b + b * b * (1.0 - 2.0 * b) ) : ( sqrt( b ) * ( 2.0 * b - 1.0 ) + 2.0 * b * ( 1.0 - b ) ); }

float ToSrgb1( float c )	{ return c < 0.0031308 ? c * 12.92 : 1.055 * pow( abs(c), 0.41666 ) - 0.055; }

vec3 ToSrgb( vec3 c )		{ return vec3( ToSrgb1( c.r ), ToSrgb1( c.g ), ToSrgb1( c.b ) ); }	

vec3 reduceColor( vec4 outColor )
{
	const vec3 palette[] = { vec3(1,1,1), vec3(1,1,1), vec3(3,1,1), vec3(1,3,1), vec3(1,1,3), vec3(3,3,3), vec3(6,5,5), vec3(7,6,6), vec3(7,7,7) };
	const vec3 ArtBpal[] = {	vec3(1.0,0.0,0.0), vec3(1.0,0.5,0.5), vec3(0.0,1.0,0.0),
								vec3(0.5,1.0,0.5), vec3(0.0,0.0,1.0), vec3(0.5,0.5,1.0),
								vec3(1.0,1.0,0.0), vec3(0.5,0.5,0.0), vec3(1.0,0.0,1.0),
								vec3(0.5,0.0,0.5), vec3(0.0,1.0,1.0), vec3(0.0,0.5,0.5),
								vec3(1.0,0.5,0.0), vec3(1.0,0.0,0.5), vec3(0.0,1.0,0.5),
								vec3(0.5,1.0,0.0), vec3(0.0,0.5,1.0), vec3(0.5,0.0,1.0),
								vec3(0.7,0.5,0.3), vec3(0.6,0.4,0.1), vec3(0.5,0.3,0.0),
								vec3(.25,.25,.25), vec3(0.5,0.5,0.5), vec3(.75,.75,.75),				
								vec3(1.0,1.0,1.0), vec3(0.0,0.0,0.0) };
	const vec3 ArtBpal2[]= {	vec3(1.0,0.5,0.5), vec3(1.0,0.0,0.0), vec3(0.5,0.0,0.0),
								vec3(0.5,1.0,0.5), vec3(0.0,1.0,0.0), vec3(0.0,0.5,0.0),
								vec3(0.5,0.5,1.0), vec3(0.0,0.0,1.0), vec3(0.0,0.0,0.5),
								vec3(1.0,1.0,0.5), vec3(1.0,1.0,0.0), vec3(0.5,0.5,0.0),
								vec3(1.0,0.5,1.0), vec3(1.0,0.0,1.0), vec3(0.5,0.0,0.5),
								vec3(0.5,1.0,1.0), vec3(0.0,1.0,1.0), vec3(0.0,0.5,0.5),
								vec3(1.0,0.5,0.0), vec3(0.7,0.5,0.2), vec3(0.5,0.3,0.0),
								vec3(.75,.75,.75), vec3(0.5,0.5,0.5), vec3(.25,.25,.25),
								vec3(1.0,1.0,1.0), vec3(0.0,0.0,0.0) };								
								
	vec3 cPal = palette[ int( params.ColorReduction - 1.0 ) ];
	if( params.ColorReduction > 1.0 )
	{
		if( params.ColorReduction < 9.0 ) outColor.rgb = round( outColor.rgb * cPal ) / cPal; else
			{
				float best_val = 1.0;
				uint  best_pal = 0;
				float temp;					
				for( int i = 0; i < 26; ++i )
				{
					temp = params.ColorReduction == 9 ? distance( outColor.rgb, ArtBpal[i] ) : distance( outColor.rgb, ArtBpal2[i] );
					if (temp < best_val)
					{
						best_val = temp;
						best_pal = i;
					}
				}
				outColor.rgb = params.ColorReduction == 9 ? ArtBpal[ best_pal ] * outColor.a : ArtBpal2[ best_pal ] * outColor.a;
			}
	} else {
		float temp = max( max( outColor.r, outColor.g ), outColor.b );
		if (temp > 0.0) outColor.rgb = vec3( floor( outColor.r/temp ),floor( outColor.g/temp ),floor( outColor.b/temp ) );
	}
	
	return outColor.rgb;
}

vec3 dotDither( vec3 color, vec2 pos, float type, float res )
{
	const int pattern[] =	{
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


	float maxBright = max( max( color.r, color.g ), color.b );
	uint nPattern;
	if( maxBright < 0.01 ) nPattern = 0; else
		if( maxBright > 0.99 ) nPattern = 10; else
			nPattern = ( maxBright < 0.5 ) ? int( ceil( maxBright * 10.0 ) ) : int( floor( maxBright * 10.0 ) );
		
	uint px			= int( pos.x * params.OutputSize.x / res);
	uint py			= int( pos.y * params.OutputSize.y / res);
	uint posStart	= pattern[ nPattern ];
	uint posColumns	= pattern[ posStart - 2 ];
	uint posLines	= pattern[ posStart - 1 ];

	uint posX		= px - posColumns * int( floor( px / posColumns ) );
	uint posY		= py - posLines * int( floor( py / posLines ) );
	
	uint posValue	= pattern[ posStart + posX + posColumns * posY ];	

	maxBright 		= ( type == 1.0 ) ? maxBright : 1.0;
	if( maxBright > 0.0 ) color = float( posValue ) * color / maxBright;
	
	return color;
}

void main()
{
	// get current sample color
	FragColor = texture(Source, vTexCoord);

	const vec3 mono[] = { vec3(0.33333,0.33333,0.33333), vec3(0.21, 0.72, 0.07), vec3(0.12, 0.72, 0.05), vec3(0.18, 0.41, 0.41), vec3(0.24, 0.37, 0.39) };

	// Dithering	
	if( params.doDither > 0.0 ) FragColor.rgb = dotDither( FragColor.rgb, vTexCoord, params.doDither, ditherRes );

	// Apply reduced color palette
	if( params.ColorReduction > 0.0 ) FragColor.rgb = reduceColor( FragColor );

	// Apply color profile
	if( params.ColorProfile != 0.0 )
	{
		if( params.ColorProfile == 1.0 ) FragColor.rgb *= vec3( 1.1, 1.0, 0.8 ); else
		if( params.ColorProfile == 2.0 ) FragColor.rgb *= vec3( 0.8, 1.0, 1.1 ); else
		if( params.ColorProfile == 3.0 ) {
					float prod = dot( mono[ int(params.MonochromeType) ], FragColor.rgb );
					FragColor.rgb = mix( vec3( prod,prod,prod ), FragColor.rgb, 0.0 ); } else
		if( params.ColorProfile == 4.0 ) {
					float prod = dot( mono[ int(params.MonochromeType) ], FragColor.rgb );
					FragColor.rgb = mix( vec3( prod,prod,prod ), FragColor.rgb, 0.0 );
					FragColor.rgb = vec3( 0.0, 1.2 * FragColor.g, 0.0 ); } else
		if( params.ColorProfile == 5.0 ) {
					float prod = dot( mono[ int(params.MonochromeType) ], FragColor.rgb );
					FragColor.rgb = mix( vec3( prod,prod,prod ), FragColor.rgb, 0.0 );
					FragColor.rgb = vec3( 1.2 * FragColor.r, 0.8 * FragColor.g, 0.0 ); } else
		if( params.ColorProfile == 6.0 ) {
					float prod = dot( mono[ int(params.MonochromeType) ], FragColor.rgb );
					FragColor.rgb = mix( vec3( prod,prod,prod ), FragColor.rgb, 0.0 );
					FragColor.rgb = vec3( 0.7 * FragColor.r, 0.7 * FragColor.g, 1.2 * FragColor.b ); } else
		if( params.ColorProfile == 7.0 ) FragColor.rgb = vec3( FragColor.r, 0.4 * FragColor.r + 0.6 * FragColor.g, FragColor.b - 0.2 * FragColor.r  ); else
		if( params.ColorProfile == 8.0 ) FragColor.rgb = ToSrgb( FragColor.rgb ) * 0.8; else
		if( params.ColorProfile == 9.0 ) FragColor.rgb = vec3(1.0 - FragColor.r, 1.0 - FragColor.g, 1.0 - FragColor.b) * FragColor.a; else
		if( params.ColorProfile == 10.0 ) {
					float prod = dot( mono[ int(params.MonochromeType) ], FragColor.rgb );
					FragColor.rgb = mix( vec3( prod,prod,prod ), FragColor.rgb, 0.0 );
					FragColor.rgb = FragColor.r > ( params.colorShift / 360.0 + 0.5 ) ? FragColor.rgb = vec3(1.0, 1.0, 1.0) : FragColor.rgb = vec3(0.0, 0.0, 0.0); }
	}
	
	// Apply Saturation
	if( params.ScreenSaturation != 0.0 ) FragColor.rgb = mix( getLum( FragColor.rgb), FragColor.rgb, params.ScreenSaturation + 1.0 );	

	// Apply Luminance
	if( params.ScreenLuminance != 0.0 )
	{
		vec3 c = 1.0 - ( 1.0 - FragColor.rgb ) * ( 1.0 - FragColor.rgb );
		FragColor.rgb = mix( FragColor.rgb, c, 2.0 * params.ScreenLuminance );
	}
	
	// Apply Brightness
	if( params.ScreenBrightness != 0.0 ) FragColor.rgb *= (1.0 + params.ScreenBrightness);

	// Apply Contrast
	if( params.ScreenContrast != 0.0 )
	{
		vec3 c = sl( FragColor.rgb );
		FragColor.rgb = mix( FragColor.rgb, c, 2.0 * params.ScreenContrast );
	}
	
	// Apply Fade
	if( params.ScreenFade != 0.0 ) if( distance( FragColor.rgb, vec3( 0.0, 0.0, 0.0 ) ) > 0.0 ) FragColor.rgb = mix( FragColor.rgb, vec3( 0.5, 0.5, 0.5 ), params.ScreenFade );

	//Apply Vibrance
	if( params.ScreenVibrance != 0.0 )
	{
		vec3 sat = vec3( 0.0, 0.0, 0.0 );
		sat.rg = vec2( min( min( FragColor.r, FragColor.g ), FragColor.b ), max( max( FragColor.r, FragColor.g ), FragColor.b ));
		sat.b = sat.g - sat.r;
		sat = getLum( sat );
		FragColor.rgb = mix( sat, FragColor.rgb, 1.0 + ( params.ScreenVibrance * ( 1.0 - sat.r )));	
	}
	
	//Apply Exposure
	if( params.ScreenExposure != 0.0 ) FragColor.rgb = clamp( FragColor.rgb * ( params.ScreenExposure * ( 1.0 - FragColor.rgb ) + vec3(1.0,1.0,1.0) ), 0.0, 1.0 );

	//Apply Color Shift
	if( params.colorShift != 0.0 )
	{
		float shift = params.colorShift / 120.0;
		vec3 OC = FragColor.rgb;
		if (shift > 0.0 && shift <= 1.0)	FragColor.rgb = vec3((1-shift)*OC.r+shift*OC.g     , (1-shift)*OC.g+shift*OC.b     , (1-shift)*OC.b+shift*OC.r);     else
						if (shift > 1.0)	FragColor.rgb = vec3((2-shift)*OC.g+(shift-1)*OC.b , (2-shift)*OC.b+(shift-1)*OC.r , (2-shift)*OC.r+(shift-1)*OC.g); else	
		if (shift >=-1.0 && shift < 0.0)	FragColor.rgb = vec3((1+shift)*OC.r-shift*OC.b     , (1+shift)*OC.g-shift*OC.r     , (1+shift)*OC.b-shift*OC.g);     else
											FragColor.rgb = vec3((2+shift)*OC.b-(shift+1)*OC.g , (2+shift)*OC.r-(shift+1)*OC.b , (2+shift)*OC.g-(shift+1)*OC.r);
	}	
	
}


