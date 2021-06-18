/*********************************************************************************************************\
*                                                                                                         *
*	ArtB. Freezie                                                                                         *
*	v1.01, 2021 by ArturoBandini                                                                          *
*	                                                                                                      *
*   This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International License     *
*   To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/4.0/                  *
*                                                                                                         *
\*********************************************************************************************************/						

#include "ReShade.fxh"
#include "ReShadeUI.fxh"


/*********************************************************************************************************/
/**** Uniforms *******************************************************************************************/
/*********************************************************************************************************/

uniform bool freezeFrame <
	ui_label = "Freeze Current Frame";
> = false;

uniform bool right_mouse	< source = "mousebutton"; keycode = 1; mode = ""; >;
uniform bool space_bar		< source = "key"; keycode = 0x20; mode = "toggle"; >;


/*********************************************************************************************************/
/**** Samplers *******************************************************************************************/
/*********************************************************************************************************/

texture2D Tex_Freeze { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
sampler2D Sampler_Freeze { Texture = Tex_Freeze; };


/*********************************************************************************************************/
/**** Render Functions ***********************************************************************************/
/*********************************************************************************************************/

float4 PS_FreezeP1(float4 pos : SV_Position, float2 coord : TEXCOORD ) : SV_Target
{
	if( freezeFrame || space_bar || right_mouse ) return tex2D( Sampler_Freeze, coord ); else
		return tex2D( ReShade::BackBuffer, coord );
}

float4 PS_FreezeP2(float4 pos : SV_Position, float2 coord : TEXCOORD) : SV_Target
{
	return tex2D( ReShade::BackBuffer, coord );
}


/*********************************************************************************************************/
/**** Render Passes **************************************************************************************/
/*********************************************************************************************************/

technique ArtB_Freezie
<
	ui_label = "ArtB Freezie";
	ui_tooltip = "Freezes Current Frame";
>
{
	pass // Freeze Pass 1
	{	VertexShader  = PostProcessVS;
		PixelShader   = PS_FreezeP1; }

    pass // Freeze Pass 2
    {   VertexShader  = PostProcessVS;
        PixelShader   = PS_FreezeP2;
		RenderTarget  = Tex_Freeze; }
}