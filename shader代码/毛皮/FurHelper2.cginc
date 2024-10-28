#pragma target 3.0

#include "Lighting.cginc"
#include "UnityCG.cginc"

struct v2f
{
    float4 pos : SV_POSITION;
    half4 uv : TEXCOORD0;
    float3 worldNormal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
};

fixed4 _Color;
fixed4 _Specular;
half _Shininess;

sampler2D _MainTex;
half4 _MainTex_ST;
sampler2D _FurTex;
half4 _FurTex_ST;

fixed _FurLength;
float _EdgeFade;
float _FurThinnesss;
fixed3 _FurShading;

float4 _ForceGlobal;
float4 _ForceLocal;

fixed4 _RimColor;
float _RimPower;



v2f vert_surface(appdata_base v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(UNITY_MATRIX_M,v.vertex).xyz;

    return o;
}

v2f vert_base(appdata_base v)
{
    v2f o;
    float time = _Time.x * 20;
    float oscillation =  sin(time);

   // 定义毛发的根部、尖端和控制点
    float3 rootPos = v.vertex;
    float randomX = frac(sin(dot(v.vertex.xy, float2(12.9898, 78.233))) * 43758.5453);
    float randomY = frac(sin(dot(v.vertex.yz, float2(93.9898, 67.345))) * 12345.6789);
    float randomZ = frac(sin(dot(v.vertex.zx, float2(45.1234, 98.765))) * 87654.3210);

    // 组合随机扰动方向并归一化
    float3 randomDir = normalize(float3(randomX, randomY, randomZ) - 0.5); // 随机方向在 (-0.5, 0.5) 范围内
    float randomStrength = 0.1; // 控制随机扰动幅度

    // 计算尖端位置，添加随机扰动
    float3 tipPos = v.vertex + v.normal * _FurLength + randomDir * randomStrength * _FurLength;
    
    // 定义贝塞尔曲线的控制点，使毛发在重力/风力影响下弯曲
    float3 controlPoint = (rootPos + tipPos) / 2.0 
                          + normalize(mul(unity_WorldToObject, _ForceGlobal).xyz + _ForceLocal.xyz) 
                          * _FurLength * FURSTEP * oscillation;

    // 贝塞尔插值计算位置
    float t = FURSTEP;
    float3 P = pow(1.0 - t, 2.0) * rootPos       // 起点
             + 2.0 * (1.0 - t) * t * controlPoint // 控制点
             + pow(t, 2.0) * tipPos;              // 终点


    o.pos = UnityObjectToClipPos(float4(P,1.0));
    o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
    o.uv.zw = TRANSFORM_TEX(v.texcoord,_FurTex);
    o.worldNormal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(UNITY_MATRIX_M,v.vertex).xyz;

    return o;
}

fixed4 frag_surface(v2f i):SV_Target
{
    float3 worldNormal = normalize(i.worldNormal);
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
    float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
    float3 halfdir = normalize( viewDir + LightDir);

    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color;
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
    fixed3 diffuse = albedo * _LightColor0 * saturate( dot(worldNormal,LightDir));
    fixed3 specular = _LightColor0 * _Specular * pow( saturate( dot(halfdir,worldNormal)),_Shininess);

    fixed3 color = ambient + diffuse + specular;
    return fixed4(color,1.0);
}

fixed4 frag_base(v2f i):SV_Target
{
    float3 worldNormal = normalize(i.worldNormal);
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
    float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
    float3 halfdir = normalize( viewDir + LightDir);

    fixed3 albedo = tex2D(_MainTex,i.uv.xy).rgb * _Color;
    albedo -= (pow(1 - FURSTEP, 3)) * _FurShading;
    half rim = 1.0 - saturate(dot(viewDir, worldNormal));
    albedo += fixed4(_RimColor.rgb * pow(rim, _RimPower), 1.0);
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
    fixed3 diffuse = albedo * _LightColor0 * saturate( dot(worldNormal,LightDir));
    fixed3 specular = _LightColor0 * _Specular * pow( saturate( dot(halfdir,worldNormal)),_Shininess);

    fixed3 color = ambient + diffuse + specular;
    fixed noise = tex2D(_FurTex, i.uv.zw * _FurThinnesss).r;
    fixed alpha = clamp(noise - (FURSTEP * FURSTEP) * _EdgeFade,0,1);
    return fixed4(color,alpha);
}