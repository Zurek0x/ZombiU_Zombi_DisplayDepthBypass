/**
 * Copyright (C) 2015-2016 Ganossa (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 
 // Ported to Reshade 3 by v00d00m4n
 
////-------------//
///**HISTOGRAM**///
//-------------////
//#define USE_HISTOGRAM 1 //[Histogram] //-Histogram effect

//>Histogram Settings<\\
//#define bHistoMix 0 //[1:0] //-Mixes the colors in the histogram
uniform bool bHistoMix <
	ui_tooltip = "Mixes the colors in the histogram.";
> = true;

#define iResolution 200 //[32:253] //-Adjust sample resolution (effects performance)
/* uniform int iResolution <
	ui_type = "drag";
	ui_min = 32; ui_max = 1024;
	ui_tooltip = "Adjust sample resolution (effects performance)";
> = 200;
*/ // Why does not it work?

//#define iVerticalScale 100 //[1:100] //-CS scale
uniform int iVerticalScale <
	ui_type = "drag";
	ui_min = 0; ui_max = 100;
	ui_tooltip = "CS scale";
> = 25;

//#define iHorizontalScale 4 //[1:4] //-CS scale
uniform int iHorizontalScale <                 
	ui_type = "drag";
	ui_min = 1; ui_max = 10;
	ui_tooltip = "CS scale";
> = 4;

//#define Histogram_ToggleKey RESHADE_TOGGLE_KEY //[undef] //-Toggle key for Histogram

//#include EFFECT_CONFIG(Ganossa)

//#if USE_HISTOGRAM

//#pragma message "Histogram by Ganossa\n"

#include "ReShade.fxh"

//namespace Ganossa
//{

texture2D detectIntTex { Width = iResolution; Height = iResolution; Format = RGBA32F; };
sampler2D detectIntColor { Texture = detectIntTex; };

texture2D detectLowTex { Width = 256; Height = 1; Format = RGBA16F; };
sampler2D detectLowColor { Texture = detectLowTex; };

void PS_Histogram_DetectInt(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectInt : SV_Target)
{
	detectInt = tex2D(ReShade::BackBuffer,texcoord);
}

void PS_Histogram_DetectLow(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectLow : SV_Target)
{
	detectLow = float4(0,0,0,0);
	float bucket = trunc(texcoord.x * 256f);
	[fastopt][loop]
	for (float i = 0.0; i <= 1; i+=1f/iResolution)
	{	[fastopt][loop]
		for ( float j = 0.0; j <= 1; j+=1f/iResolution )
		{
			float3 level = trunc(tex2D(detectIntColor,float2(j,i)).xyz*256f);
			detectLow.xyz += (level == bucket);
		}
	}
	detectLow.xyz /= float(iResolution*iResolution)/iVerticalScale;
}

float4 PS_Histogram_Display(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float3 data = tex2D(detectLowColor,texcoord.x*iHorizontalScale).xyz;
	float3 orig = tex2D(ReShade::BackBuffer,texcoord).xyz;
	float4 hg = float4(0,0,0,1);
	if(texcoord.x < (1./iHorizontalScale-BUFFER_RCP_WIDTH)) {
   //#if bHistoMix
   if (bHistoMix)
   {
    if(texcoord.y > 1-data.x) hg += float4(1,0,0,0); 
	  if(texcoord.y > 1-data.y) hg += float4(0,1,0,0); 
	  if(texcoord.y > 1-data.z) hg += float4(0,0,1,0); 
	 if(max(hg.x,max(hg.y,hg.z)) == 0) hg = float4(orig,0)*0.5;
   //#else
   } else {
	  if(texcoord.y < 0.33) { if(texcoord.y+0.66 > 1-data.x ) hg += float4(1,0,0,0); else hg = float4(orig,0)*0.5; }
	  if(texcoord.y < 0.66 && texcoord.y > 0.33) { if(texcoord.y+0.33 > 1-data.y) hg += float4(0,1,0,0); else hg = float4(orig,0)*0.5; }
	  if(texcoord.y > 0.66) { if(texcoord.y > 1-data.z) hg += float4(0,0,1,0); else hg = float4(orig,0)*0.5; }
   //#endif
   }
	} else hg = float4(orig,0);
	return hg;
}

technique Histogram
{
	pass Histogram_DetectInt
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Histogram_DetectInt;
		RenderTarget = detectIntTex;
	}

	pass Histogram_DetectLow
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Histogram_DetectLow;
		RenderTarget = detectLowTex;
	}

	pass Histogram_Display
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Histogram_Display;
	}
}

//}

//#endif

// #include EFFECT_CONFIG_UNDEF(Ganossa)