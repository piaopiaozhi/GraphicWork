Shader "Final/Crystal"
{
    Properties
    {
        _Color ("Base Color", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.9
        _RefractAmount("Refraction Amount", Range(0, 1)) = 1 // 折射比例(用于漫反射和折射之间插值)
        _RefractRatio("Refraction Ratio", Range(0.1, 1)) = 0.5 // 折射比(入射介质折射率/折射介质折射率)
        _FresnelPower ("Fresnel Power", Float) = 2.0
        
         _ReflectionProbe ("Reflection Texture", Cube) = "" {}
         _RefrDistortion("RefrDistortion",Range(0,1)) = 1  //折射强度
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200
        GrabPass {"_GrabTexture"} // 抓取屏幕纹理
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include  "Lighting.cginc"
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

             struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float4 scrPos : TEXCOORD2; // 屏幕空间顶点坐标(_RefractionTex采样的uv坐标)
            };

            samplerCUBE _ReflectionProbe;
            float4 _Color;
            float _Smoothness;
            float _RefractAmount;
            float _RefractRatio;
            float _FresnelPower;
            
            sampler2D _GrabTexture; // 屏幕纹理
            float _RefrDistortion;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos); // 屏幕空间顶点坐标(_RefractionTex采样的uv坐标)
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 归一化法线
                float3 normal = normalize(i.worldNormal);
                // 灯光向量(顶点指向光源)
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); 
                // 摄像机方向
                float3 viewDir = normalize(i.worldPos - _WorldSpaceCameraPos);
                
                // Fresnel 效应
                float fresnel = pow(1.0 - dot(viewDir, normal), _FresnelPower);
                
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(normal, worldLightDir)*0.5+0.5); // 漫反射光颜色
                // 折射方向
                float3 refraction = normalize( refract(viewDir, normal, _RefractRatio ));
                

                float3 reflection = reflect(-viewDir, normal);
                float3 reflectedColor = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflection).rgb;

                float offset = 1 - dot(-viewDir, normalize(refraction));
                // 折射偏移
                float2 cameraViewDir = normalize(mul(unity_MatrixV, float4(viewDir, 0)).xy); // 观察坐标系下观察向量坐标
                float2 offsetpos = 1*normal.xz*_RefrDistortion + i.scrPos.xy / i.scrPos.w;
                offsetpos = clamp(offsetpos, 0.0, 1.0); // 限制UV坐标在[0, 1]范围内
                fixed3 refractionColor = tex2D(_GrabTexture, offsetpos).rgb; // 折射光颜色
                
                fixed3 Color1 = lerp(diffuse,reflectedColor,saturate(fresnel));
                
                // 最终透明颜色
                fixed3 color =  lerp(Color1, refractionColor, _RefractAmount); // 漫反射光与折射光颜色进行插值
                return fixed4(color,0.9);
            }
            ENDCG
        }
    }
}
