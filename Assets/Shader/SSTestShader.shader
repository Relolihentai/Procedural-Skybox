Shader "Custom/SSTestShader"
{
    Properties
    {
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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
            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            float4 frag(v2f i) : SV_TARGET0
            {
                float3 posTmp = GetWorldSpacePosition(i.uv);
                return float4(posTmp, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
