Shader "Unlit/Pulse"
{
	Properties
	{
		iChannel0 ("Texture", 2D) = "white" {}
        _Pulse("Pulse", Range(30, 120)) = 60
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
            #pragma fragment frag

            #include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D iChannel0;
			float4 _MainTex_ST;
            float _Pulse;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
            
            #define CORRECT_TEXTURE_SIZE 0
            #define TEXTURE_DOWNSCALE 1.0

            #define VIEW_HEIGHT 0
            #define VIEW_NORMALS 0
            #define CHEAP_NORMALS 1

            #define nsin(x) (sin(x) * 0.5 + 0.5)

            float rand(float2 uv, float t) {
                float seed = dot(uv, float2(12.3435, 25.3746));
                return frac(sin(seed) * 234536.3254 + t);
            }

            float2 scale_uv(float2 uv, float2 scale, float2 center) {
                return (uv - center) * scale + center;
            }

            float2 scale_uv(float2 uv, float2 scale) {
                return scale_uv(uv, scale, float2(0.5, 0.5));
            }

            float create_ripple(float2 coord, float2 ripple_coord, float scale, float radius, float range, float height) {
                float dist = distance(coord, ripple_coord);
                return sin(dist / scale) * height * smoothstep(dist - range, dist + range, radius);
            }

            float2 get_normals(float2 coord, float2 ripple_coord, float scale, float radius, float range, float height) {
                return float2(
                    create_ripple(coord + float2(1.0, 0.0), ripple_coord, scale, radius, range, height) -
                    create_ripple(coord - float2(1.0, 0.0), ripple_coord, scale, radius, range, height),
                    create_ripple(coord + float2(0.0, 1.0), ripple_coord, scale, radius, range, height) -
                    create_ripple(coord - float2(0.0, 1.0), ripple_coord, scale, radius, range, height)
                ) * 0.5;
            }

            float2 get_center(float2 coord, float t) {
                t = round(t + 0.5);
                return float2(0.5,0.5
                    //nsin(t - cos(t + 2354.2345) + 2345.3),
                    //nsin(t + cos(t - 2452.2356) + 1234.0)
                ) * _ScreenParams.xy;
            }
            
            float _TimeFromCSharp;
			
			fixed4 frag(v2f_img i) : SV_Target
			{
                //fixed2 uv = i.uv.xy;
                float2 ps = float2(1.0, 1.0) / _ScreenParams.xy;
                
                float2 uv = (i.uv);// * ps; //?
                
                #if CORRECT_TEXTURE_SIZE
                float2 tex_size = float2(textureSize(iChannel0, 0));
                uv = scale_uv(uv, (iResolution.xy / tex_size) * float(TEXTURE_DOWNSCALE));
                #endif
                
                float timescale = _Pulse/60;
                float t = frac(_TimeFromCSharp * timescale);
                
                //float timescale = 48.0/60.0;
                //float t = fract((0.19 / timescale) * timescale);
                
                //vec2 center = (iMouse.z > 0.0) ? iMouse.xy : get_center(coord, iTime * timescale);
                float2 center = get_center((i.uv * _ScreenParams.xy), _Time.y * timescale);
                
                #if CHEAP_NORMALS
                //float height = create_ripple((i.uv * _ScreenParams.xy), center, t * 100.0 + 1.0, 300.0, 300.0, 300.0);
                float height = create_ripple((i.uv * _ScreenParams.xy), center, t * 40.0 + 1.0, 0.35 * _ScreenParams.y, 400.0, 200.0);
                //float2 normals = float2(dFdx(height), dFdy(height));
                float2 normals = float2(ddx(height), ddy(height));
                #else
                float2 normals = get_normals((i.uv * _ScreenParams.xy), center, t * 100.0 + 1.0, 0.35 * _ScreenParams.y, 300.0, 300.0);
                #endif
                
                #if VIEW_HEIGHT
                fixed4 color = float4(height, height, height, height);
                #elif VIEW_NORMALS
                color = float4(normals, 0.5, 1.0);
                #else
                fixed4 color = tex2D(iChannel0, uv + normals * ps);
                #endif
				return color;
			}
			ENDCG
		}
	}
}
