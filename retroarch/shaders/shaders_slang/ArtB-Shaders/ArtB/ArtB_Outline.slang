#version 450

/*********************************************************************************************************\
*                                                                                                         *
*   ArtB. Outline                                                                                         *
*   v2.00, 2021 by ArturoBandini                                                                          *
*                                                                                                         *
*   This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License     *
*   To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/                  *
*                                                                                                         *
\*********************************************************************************************************/

layout(push_constant) uniform Push
{
	vec4 OutputSize;

	float outline_mode;
	float outline_cRed;
	float outline_cGreen;
	float outline_cBlue;
	float use_thresh_color;
	float threshold_Mono;
	float threshold_Color;
	float threshold_Red;
	float threshold_Green;
	float threshold_Blue;
	float color_mode;
	float inverted;
	float doDither;
	
} params;

#pragma parameter outline_mode     "Mode: 0|Classic  1|Filled  2|Special"		0.00 0.00  2.00 1.00
#pragma parameter outline_cRed     "BaseColor Red"								0.0  0.0  255.0  1.0
#pragma parameter outline_cGreen   "BaseColor Green"							0.0  0.0  255.0  1.0
#pragma parameter outline_cBlue    "BaseColor Blue"								0.0  0.0  255.0  1.0
#pragma parameter use_thresh_color "Threshold: 0|No  1|All Color  2|RGB Colors"	0.00 0.00  2.00 1.00
#pragma parameter threshold_Mono   "Threshold: Monochrome"						0.01 0.01  1.00 0.01
#pragma parameter threshold_Color  "Threshold: All Colors"						2.50 1.00 20.00 0.01
#pragma parameter threshold_Red    "Threshold: Color Red"						2.50 1.00 20.00 0.01
#pragma parameter threshold_Green  "Threshold: Color Green"						2.50 1.00 20.00 0.01
#pragma parameter threshold_Blue   "Threshold: Color Blue"						2.50 1.00 20.00 0.01
#pragma parameter color_mode       "Mode: 0|Colors  1|Greyscale  2|Monochrome"	0.00 0.00  2.00 1.00
#pragma parameter inverted         "Enable Inverted Mode"						0.00 0.00  1.00 1.00
#pragma parameter doDither		   "Dithering: 0|None  1|Amplified  2|Damped"	0.00 0.00  2.00 1.00

#define ditherRes 1.0;

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
	
	// get pixel size
	float px = 1.0/params.OutputSize.x;
	float py = 1.0/params.OutputSize.y;

	// define central pixel color and 4 neighbours
	vec4 col0 = FragColor;
	vec4 col1, col2, col3, col4;	

	vec3 outline_color = vec3(params.outline_cRed,params.outline_cGreen,params.outline_cBlue);
	
	// get color of 4 neighbour pixels
	col1 =  texture(Source, vec2(vTexCoord.x - px, vTexCoord.y));
	col2 =  texture(Source, vec2(vTexCoord.x + px, vTexCoord.y));
	col3 =  texture(Source, vec2(vTexCoord.x, vTexCoord.y - py));
	col4 =  texture(Source, vec2(vTexCoord.x, vTexCoord.y + py));

	// try to eliminate too many colors
	if (params.use_thresh_color > 0)
	{
		float d1 = params.threshold_Color * 0.05;
		float d2 = d1;
		float d3 = d1;
		float t1 = params.threshold_Color;
		float t2 = t1;
		float t3 = t1;

		if (params.use_thresh_color == 2)
		{
			d1 = params.threshold_Red * 0.05;
			d2 = params.threshold_Green * 0.05;
			d3 = params.threshold_Blue * 0.05;
			t1 = params.threshold_Red;
			t2 = params.threshold_Green;
			t3 = params.threshold_Blue;
		}

		// number of colors is reduced by truncating
		col0.rgb = vec3(floor(t1*col0.r+d1)/t1, floor(t2*col0.g+d2)/t2, floor(t3*col0.b+d3)/t3);
		col1.rgb = vec3(floor(t1*col1.r+d1)/t1, floor(t2*col1.g+d2)/t2, floor(t3*col1.b+d3)/t3);
		col2.rgb = vec3(floor(t1*col2.r+d1)/t1, floor(t2*col2.g+d2)/t2, floor(t3*col2.b+d3)/t3);
		col3.rgb = vec3(floor(t1*col3.r+d1)/t1, floor(t2*col3.g+d2)/t2, floor(t3*col3.b+d3)/t3);
		col4.rgb = vec3(floor(t1*col4.r+d1)/t1, floor(t2*col4.g+d2)/t2, floor(t3*col4.b+d3)/t3);
	}

	// how many neighbours do have the same color?
	int count = 0;
	if (col0.r==col1.r && col0.g==col1.g && col0.b==col1.b) count++;
	if (col0.r==col2.r && col0.g==col2.g && col0.b==col2.b) count++;
	if (col0.r==col3.r && col0.g==col3.g && col0.b==col3.b) count++;
	if (col0.r==col4.r && col0.g==col4.g && col0.b==col4.b) count++;
	
	// type of outline mode. Mode 3 is some kind of color mashing
	
	if (params.outline_mode == 0 && count == 4) FragColor.rgb = outline_color * FragColor.a;
	
	if (params.outline_mode == 1 && ((count == 3) || (count == 2 &&
						(col1.r!=col2.r && col3.r!=col4.r) ||
						(col1.g!=col2.g && col3.g!=col4.g) ||
						(col1.b!=col2.b && col3.b!=col4.b ))))
						FragColor.rgb = outline_color; //else
							if( params.doDither > 0.0 ) FragColor.rgb = dotDither( FragColor.rgb, vTexCoord, params.doDither, 1.0 );
						
	if (params.outline_mode == 2 && ((count >= 3) || (count == 2 &&
						(col1.r!=col2.r && col3.r!=col4.r) ||
						(col1.g!=col2.g && col3.g!=col4.g) ||
						(col1.b!=col2.b && col3.b!=col4.b )))) {
							FragColor.rgb = (col0.rgb + col1.rgb + col2.rgb + col3.rgb + col4.rgb)/5;
							if( params.doDither > 0.0 ) FragColor.rgb = dotDither( FragColor.rgb, vTexCoord, params.doDither, 1.0 );
						}

	//vec3 test;
	//test = dotDither( test, vec2(0.0,0.0), 1.0, 1.0 );


	// calculate greyscale and monochrome values	
	float color = (FragColor.r + FragColor.g + FragColor.b) / 3.0;
	if (params.color_mode == 2) FragColor.rgb = color < params.threshold_Mono ? vec3(0.0,0.0,0.0) : vec3(1.0,1.0,1.0); else
		if (params.color_mode == 1) FragColor.rgb = vec3(color,color,color);

	// invert colors, depending on color mode
	if (params.inverted == 1.0 && FragColor.a != 0.0)
	{
		if (params.color_mode == 0.0)
		{
			if ((FragColor.r + FragColor.g + FragColor.b) < 0.1) FragColor.rgb=vec3(1.0,1.0,1.0) * FragColor.a; else
				if ((FragColor.r + FragColor.g + FragColor.b) > 2.7) FragColor.rgb=vec3(0.0,0.0,0.0) * FragColor.a;
		} else FragColor.rgb = 1.0 - FragColor.rgb;			
	}

}


