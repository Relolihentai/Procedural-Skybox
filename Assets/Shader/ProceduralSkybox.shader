// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/ProceduralSkybox"
{
    Properties
    {
        //��������������뾶
        _EarthGroundRadius("Earth Ground Radius", Float) = 20000
        //�������
        _AtmosphereThickness("Atmosphere Thickness", Float) = 10000
        //��ɫ
        _RayleightColor("Rayleight Color", Color) = (0.0441082, 0.09770209, 0.1320755, 1)
        _MieColor("Mie Color", Color) = (0.3882353, 0.3313319, 0.2470588, 1)
        //���ʴ����߶�
        _RayleightHomogeneousAtmosphere("Rayleight Homogeneous Atmosphere", Float) = 250
        _MieHomogeneousAtmosphere("Mie Homogeneous Atmosphere", Float) = 125
        //����
        _Brightness("Brightness", Float) = 10
        //��������
        _SampleNum("Sample Number", Int) = 100
        _SampleLightNum("Sample Light Number", Int) = 20
        //Mie��λ����ϵ��
        _g("Mie Phase g", Float) = -0.78
        //Mie΢��ϵ��
        _MieAdjust("Mie Adjust", Float) = 1.5
        //_PosAdjust("Pos Adjust", Float) = 100
    }
    SubShader
    {
        Tags{"LightMode" = "ForwardBase"}
        Pass
        {
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #define PI 3.1415926536
            //��������

            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;

            float4x4 _InverseViewMatrix;
            float4x4 _InverseProjectionMatrix;
            
            float _EarthGroundRadius;
            float _AtmosphereThickness;
            float _Brightness;
            float4 _RayleightColor;
            float4 _MieColor;
            float _RayleightHomogeneousAtmosphere;
            float _MieHomogeneousAtmosphere;
            float _SampleNum;
            float _SampleLightNum;
            float _g;
            float _MieAdjust;
            //float _PosAdjust;
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
            float3 GetWorldSpacePosition(float2 i_UV)
            {
	            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i_UV);

	            float4 positionViewSpace = mul(_InverseProjectionMatrix, float4(2.0 * i_UV - 1.0, depth, 1.0));
	            positionViewSpace /= positionViewSpace.w;


	            float3 positionWorldSpace = mul(_InverseViewMatrix, float4(positionViewSpace.xyz, 1.0)).xyz;
	            return positionWorldSpace;
            }
            //�����Ƕȣ�����ýǶȣ���Դ����Ͳ����㣨�͵������ߣ��ļнǣ��£��߶�Ϊ��ʱ�Ĺ�ѧ���
            //�иýǶȣ��õ㣩�ڸ߶��㴦�Ĺ�ѧ���֮�󣬳��Թ�һ��֮��Ĺ�ѧ��ȱȺ�������h1 / h0�����Ϳ��Եõ��õ�Ĺ�ѧ���
            //�Ż���Ҫ��ֱ������һ����֣�ԭ����ѧ���Ҫһ��һ���ۼ�
            float AtmoRhoInZero(float cos)
            {
                float x = 1.0 - cos;
                return 0.25 * exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x  * 5.25))));
            }
            //�õ�������Ľ���
            float2 GetPoint(float3 Pos, float3 ViewDir, float3 Center, float Radius)
            {
                Pos -= Center;
                float a = 1;
                float b = 2.0 * dot(Pos, ViewDir);
                float c = dot(Pos, Pos) - (Radius * Radius);
                float delta = b * b - 4 * a * c;
                if(delta < 0) return -1;
                else 
                {
                    float FinDelta = sqrt(delta);
                    return float2(-b - FinDelta, -b + FinDelta) / 2 * a;
                }
            }
            //����ɢ��Ĵ����ܶȱ���
            float RayleightGetAtmoRho(float Height)
            {
                return exp(-max(Height, 0) / _RayleightHomogeneousAtmosphere);
            }
            float MieGetAtmoRho(float Height)
            {
                return exp(-max(Height, 0) / _MieHomogeneousAtmosphere);
            }
            //����ɢ�����λ����
            float RayleightPhase(float AngleCos)
            {
                return (0.1875 / PI) * (1 + AngleCos * AngleCos);
            }
            float MiePhase(float AngleCos)
            {
                float _g2 = _g * _g;
                float upTmp = (1.0 - _g2) * (1 + AngleCos * AngleCos);
                float downTmp1 = 2.0 + _g2;
                float downTmp2 = 1.0 + _g2 - 2.0 * _g * AngleCos;
                float downTmp = pow(downTmp2, 1.5) * downTmp1;
                return (3.0  / 8.0 / PI ) * (upTmp / downTmp);
            }
            //������ɫ��
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            float4 frag(v2f i) : SV_TARGET0
            {
                //��������������뾶
                float AllEarthRadius = _EarthGroundRadius + _AtmosphereThickness;
                //������������
                //float3 EarthCenter = mul(unity_ObjectToWorld, float4(0, -AllEarthRadius, 0, 1)).xyz;
                float3 EarthCenter = float4(0, -_EarthGroundRadius, 0, 1);

                float3 worldPos = GetWorldSpacePosition(i.uv);
                
                //�����λ�ú��ӽǷ���
                float3 CameraPos = _WorldSpaceCameraPos;
                float3 CameraViewDir = normalize(worldPos - CameraPos);
                //�õ������������Զ������
                //x����Ϊ���㣬y����ΪԶ��
                float2 PointLength = GetPoint(CameraPos, CameraViewDir, EarthCenter, AllEarthRadius);
                //û�н���
                if (PointLength.y <= 0 && PointLength.x <= 0) return float4(0.0, 0.0, 0.0, 0.0);
                //����������ֵ������ͬʱ��������������ڴ����ڵ����
                PointLength.x = max(PointLength.x, 0);
                PointLength.y = max(PointLength.y, 0);
                //������
                float3 SamplePoint = CameraPos + CameraViewDir * PointLength.x;
                //�����������Ͳ�������
                float SampleLength = PointLength.y - PointLength.x;
                float SampleStep = SampleLength / _SampleNum;
                float3 SampleStepDir = CameraViewDir * SampleStep;
                
                float RayleightInScatterSum = 0;
                float MieInScatterSum = 0;

                float3 Rayleight = float3(0, 0, 0);
                float3 Mie = float3(0, 0, 0);

                for(int k = 0; k < _SampleNum; k++)
                {
                    float SamplePointHeight = length(SamplePoint - EarthCenter) - _EarthGroundRadius;
                    if(SamplePointHeight < 0) break;

                    float OneRayleightInScatter = RayleightGetAtmoRho(SamplePointHeight) * SampleStep;
                    float OneMieInScatter = MieGetAtmoRho(SamplePointHeight) * SampleStep;

                    RayleightInScatterSum += OneRayleightInScatter;
                    MieInScatterSum += OneMieInScatter;

                    //_WorldSpaceLightPos0Ϊ��Դ����ƽ�й⣩������ռ��λ��
                    float3 LightDir = normalize(_WorldSpaceLightPos0);
                    //float2 LightDirPointLength = GetPoint(SamplePoint, LightDir, EarthCenter, AllEarthRadius);

                    //float SampleLightLength = LightDirPointLength.y;
                    //float SampleLightStep = SampleLightLength / _SampleLightNum;
                    //float3 SampleLightStepDir = LightDir * SampleLightStep;
                    //�ò����������
                    //float3 SampleLightPoint = SamplePoint;
                    //��ɢ��˥��
                    //�ǹ��ߴ� ��������� �� ���� �ڼ��˥�����
                    float3 SamplePointDir = (SamplePoint - EarthCenter) / (_EarthGroundRadius + SamplePointHeight);
                    float LightAngle = dot(SamplePointDir, LightDir);
                    //float CameraAngle = dot(SamplePointDir, CameraViewDir);
                    
                    
                    float RayleightOutScatterSum = 1;
                    float MieOutScatterSum = 1;

                    float CP_Scatter = AtmoRhoInZero(LightAngle) * exp(-4 * (SamplePointHeight / _AtmosphereThickness));
                    
                    /*for(int j = 0; j < _SampleLightNum; j++)
                    {
                        float SampleLightPointHeight = length(SampleLightPoint - EarthCenter) - _EarthGroundRadius;
                        RayleightOutScatterSum += RayleightGetAtmoRho(SampleLightPointHeight);
                        MieOutScatterSum += MieGetAtmoRho(SampleLightPointHeight);
                        SampleLightPoint += SampleLightStepDir;
                    }*/
                    RayleightOutScatterSum *= CP_Scatter;
                    MieOutScatterSum *= CP_Scatter;
                    float3 AllScatter = exp(-((RayleightInScatterSum + RayleightOutScatterSum) * _RayleightColor 
                                            + (MieInScatterSum + MieOutScatterSum) * _MieColor * _MieAdjust)); 
                    Rayleight += OneRayleightInScatter * AllScatter;
                    Mie += OneMieInScatter * AllScatter;
                    SamplePoint += SampleStepDir;
                }
                float PointToCameraCos = -dot(CameraViewDir, _WorldSpaceLightPos0);
                float3 FinalColor = _LightColor0 * _Brightness * ((Rayleight * RayleightPhase(PointToCameraCos) * _RayleightColor)
                                                + (Mie * MiePhase(PointToCameraCos) * _MieColor * _MieAdjust));
                //������Ҫ��һ��HDR
                return float4(min(FinalColor, float3(1, 1, 1)), 1);
                //return float4(FinalColor, 1);
                //return float4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
