Shader "CustomShader/Shader_SingleAtmosphere"
{
    Properties
    {
        _PlanetRadius("Planet Radius", Float) = 6371000.0
		_AtmosphereHeight("Atmosphere Height", Float) = 8000.0
		_SunIntensity("Sun Intensity", Float) = 1.0
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert;
            #pragma fragment frag;
            #include "UnityCG.cginc"
            float _PlanetRadius;
			float _AtmosphereHeight;
			float _SunIntensity;
            struct appdata
            {
	            float4 vertex : POSITION;
	            float2 uv : TEXCOORD0;
            };

            struct v2f
            {
	            float4 vertex : SV_POSITION;
	            float2 uv : TEXCOORD0;
            };


            v2f vert(appdata v)
            {
	            v2f o;
	            o.vertex = UnityObjectToClipPos(v.vertex);
	            o.uv = v.uv;
	            return o;
            }

            float4x4 _InverseViewMatrix;
            float4x4 _InverseProjectionMatrix;

            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;

            float3 GetWorldSpacePosition(float2 i_UV)
            {
	            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i_UV);

	            float4 positionViewSpace = mul(_InverseProjectionMatrix, float4(2.0 * i_UV - 1.0, depth, 1.0));
	            positionViewSpace /= positionViewSpace.w;


	            float3 positionWorldSpace = mul(_InverseViewMatrix, float4(positionViewSpace.xyz, 1.0)).xyz;
	            return positionWorldSpace;
            }

            float2 RaySphereIntersection(float3 rayOrigin, float3 rayDir, float3 sphereCenter, float sphereRadius)
			{
				rayOrigin -= sphereCenter;
				float a = dot(rayDir, rayDir);
				float b = 2.0 * dot(rayOrigin, rayDir);
				float c = dot(rayOrigin, rayOrigin) - (sphereRadius * sphereRadius);
				float d = b * b - 4 * a * c;
				if (d < 0)
				{
					return -1;
				}
				else
				{
					d = sqrt(d);
					return float2(-b - d, -b + d) / (2 * a);
				}
			}
            float4 frag(v2f i) : SV_TARGET0
            {
	            float3 positionWorldSpace = GetWorldSpacePosition(i.uv);
	            return float4(positionWorldSpace, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
