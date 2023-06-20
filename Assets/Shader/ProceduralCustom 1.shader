// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/ProceduralCustom1"
{
    Properties
    {
        //��������������뾶
        _EarthGroundRadius("Earth Ground Radius", Float) = 6.0
        //�������
        _AtmosphereThickness("Atmosphere Thickness", Float) = 3.0
        //��ɫ
        _RayleightColor("Rayleight Color", Color) = (1, 1, 1, 1)
        _MieColor("Mie Color", Color) = (1, 1, 1, 1)
        //���ʴ����߶�
        _RayleightHomogeneousAtmosphere("Rayleight Homogeneous Atmosphere", Float) = 0.2
        _MieHomogeneousAtmosphere("Mie Homogeneous Atmosphere", Float) = 0.1
        //���ȣ����Ǻ������ϵ������ϣ�
        _Brightness("Brightness", Float) = 10
        //��������
        _SampleNum("Sample Number", Int) = 100
        _SampleLightNum("Sample Light Number", Int) = 6
        //Mie��λ����ϵ��
        _G("Mie Phase g", Float) = -0.78
        //Mie΢��ϵ��
        _MieAdjust("Mie Adjust", Float) = 2.1
    }
    SubShader
    {
        Pass
        {
            Cull Off
            Blend One OneMinusSrcColor
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #define PI 3.1415926536
            //��������
            float _EarthGroundRadius;
            float _AtmosphereThickness;
            float _Brightness;
            float4 _RayleightColor;
            float4 _MieColor;
            float _RayleightHomogeneousAtmosphere;
            float _MieHomogeneousAtmosphere;
            float _SampleNum;
            float _SampleLightNum;
            float _G;
            float _MieAdjust;
            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            struct v2f 
            {
                float4 pos : SV_POSITION;
                //�����˶������������
                float4 worldPos : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };
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
            float RayleightGetAtmoRho(float Height)
            {
                return exp(-max(Height, 0) / _RayleightHomogeneousAtmosphere);
            }
            float MieGetAtmoRho(float Height)
            {
                return exp(-max(Height, 0) / _MieHomogeneousAtmosphere);
            }
            float RayleightPhase(float AngleCos)
            {
                return (0.1875 / PI) * (1 + AngleCos * AngleCos);
            }
            float MiePhase(float AngleCos)
            {
                float _G2 = _G * _G;
                float MA = (1.0 - _G2) * (1 + AngleCos * AngleCos);
                float MB_L = 2.0 + _G2;
                float MB_R = 1.0 + _G2 - 2.0 * _G * AngleCos;
                MB_R = pow(MB_R, 1.5) * MB_L;
                return (3.0  / 8.0 / PI ) * (MA / MB_R);
            }
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }
            float4 frag(v2f i) : SV_TARGET0
            {
                //��������������뾶
                float AllEarthRadius = _EarthGroundRadius + _AtmosphereThickness;
                //������������
                float3 EarthCenter = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
                //�����λ�ú��ӽǷ���
                float3 CameraPos = _WorldSpaceCameraPos;
                float3 CameraViewDir = i.worldPos - CameraPos;
                //�õ������������Զ������
                //x����Ϊ���㣬y����ΪԶ��
                //float2 PointLength = GetPoint(CameraPos, CameraViewDir, EarthCenter, AllEarthRadius);

                //if (PointLength.y <= 0 && PointLength.x <= 0) return float4(0.0, 0.0, 0.0, 0.0);

                //PointLength.x = max(PointLength.x, 0);
                //PointLength.y = max(PointLength.y, 0);
                //float3 SamplePoint = CameraPos + CameraViewDir * PointLength.x;
                //�����������Ͳ�������
                float SampleLength = length(CameraViewDir);
                CameraViewDir = normalize(CameraViewDir);
                float SampleStep = SampleLength / _SampleNum;
                float3 SampleStepDir = CameraViewDir * SampleStep;
                float3 SamplePoint = CameraPos;

                //��ɢ��˥��
                //�ǹ��ߴ� ���� ���� ����������㣩 �ڼ��˥�����
                //
                float RayleightInScatterSum = 0;
                float MieInScatterSum = 0;

                //float3 AllRayleightScatter = float3(0, 0, 0);
                //float3 AllMieScatter = float3(0, 0, 0);

                float3 Rayleight = float3(0, 0, 0);
                float3 Mie = float3(0, 0, 0);

                for(int i = 0; i < _SampleNum; i++)
                {
                    float SamplePointHeight = length(SamplePoint) - _EarthGroundRadius;
                    if(SamplePointHeight < 0) break;

                    float OneRayleightInScatter = RayleightGetAtmoRho(SamplePointHeight) * SampleStep;
                    float OneMieInScatter = MieGetAtmoRho(SamplePointHeight) * SampleStep;

                    RayleightInScatterSum += OneRayleightInScatter;
                    MieInScatterSum += OneMieInScatter;

                    //_WorldSpaceLightPos0Ϊ��Դ����ƽ�й⣩������ռ��λ��
                    float3 LightDir = normalize(_WorldSpaceLightPos0);
                    float2 LightDirPointLength = GetPoint(SamplePoint, LightDir, EarthCenter, AllEarthRadius);

                    float SampleLightLength = max(LightDirPointLength.y, LightDirPointLength.x);
                    float SampleLightStep = SampleLightLength / _SampleLightNum;
                    float3 SampleLightStepDir = LightDir * SampleLightStep;
                    //�ò����������
                    float3 SampleLightPoint = SamplePoint;
                    //��ɢ��˥��
                    //�ǹ��ߴ� ��������� �� ���� �ڼ��˥�����
                    //����ͬ��
                    float RayleightOutScatterSum = 0;
                    float MieOutScatterSum = 0;

                    for(int j = 0; j < _SampleLightNum; j++)
                    {
                        float SampleLightPointHeight = length(SampleLightPoint) - _EarthGroundRadius;
                        RayleightOutScatterSum += RayleightGetAtmoRho(SampleLightPointHeight);
                        MieOutScatterSum += MieGetAtmoRho(SampleLightPointHeight);
                        SampleLightPoint += SampleLightStepDir;
                    }
                    RayleightOutScatterSum *= SampleLightStep;
                    MieOutScatterSum *= SampleLightStep;
                    //AllRayleightScatter += exp(-(RayleightInScatterSum + RayleightOutScatterSum) * _RayleightColor);
                    //AllMieScatter += exp(-(MieInScatterSum + MieOutScatterSum) * _MieColor * _MieAdjust);
                    float3 AllScatter = exp(-((RayleightInScatterSum + RayleightOutScatterSum) * _RayleightColor 
                                            + (MieInScatterSum + MieOutScatterSum) * _MieColor * _MieAdjust)); 
                    Rayleight += OneRayleightInScatter * AllScatter;
                    Mie += OneMieInScatter * AllScatter;
                    SamplePoint += SampleStepDir;
                }
                float PointToCameraCos = -dot(CameraViewDir, _WorldSpaceLightPos0);
                float3 FinalColor = _Brightness * ((Rayleight * RayleightPhase(PointToCameraCos) * _RayleightColor)
                                                + (Mie * MiePhase(PointToCameraCos) * _MieColor));
                return float4(min(FinalColor, float3(1, 1, 1)), 1);
                //return float4(FinalColor, 1);
                //return float4(0, 0, 0, 1);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
