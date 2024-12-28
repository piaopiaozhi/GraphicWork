Shader "Final/Grass_LOD0"
{
    Properties
    {
        _Color("Main Tint",Color) = (1,1,1,1) // 主色调
        _MainTex ("Texture", 2D) = "white" {}// 主纹理
        _SmoothnessTex("SmoothnessTex",2D) = "white"{}// 光滑度纹理
        _Cutoff("Cutoff",Range(0,1)) = 0.3 // 透明度裁切
        
        
        _Color1("Color1",Color) = (1,1,1,1) // 颜色渐变起点
        _Color2("Color2",Color) = (1,1,1,1) // 颜色渐变终点
        _ColorControl("ColorControl",Range(0,10)) = 0.5 // 颜色混合控制
        _ColorRange("ColorRange",Range(0,1)) = 1 // 颜色渐变范围
        
        
        _SpecularColor("SpecularColor",Color) = (1,1,1,1) // 高光颜色
        _Gloss("Gloss",Range(0,10)) = 1 // 光泽强度
        _Specular("Specular",Range(0,128)) = 1 // 高光指数最大值
        _SpecularMin("_SpecularMin",Range(0,128)) = 1 // 高光指数最小值
        
        _WindSpeed("WindSpeed",Range(0,128))  = 1 // 风速
        _OffsetAtten("OffsetAtten",Vector)= (0.1,0.1,0.3) // 风偏移强度
        
        _InteractionDistance("InteractionDistance",Float) = 1 // 踩踏交互距离
        _TreadStrength("TreadStrength",Float) = 1 // 踩踏强度
        
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 100
        Cull Off // 关闭背面剔除
        

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include  "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION; // 顶点坐标
                float2 uv : TEXCOORD0; // UV坐标
                float3 normal :NORMAL; // 法线
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0; // UV坐标
                float4 pos : SV_POSITION; // 裁剪空间坐标
                float3 normal : TEXCOORD1; // 世界空间法线
                float3 worldPos : TEXCOORD2; // 世界空间位置
                SHADOW_COORDS(3) // 阴影坐标
            };

            fixed4 _Color; // 主色调
            sampler2D _MainTex; // 主纹理
            sampler2D _SmoothnessTex; // 光滑度纹理
            float4 _MainTex_ST; // 主纹理缩放与偏移
            fixed4 _Color1; // 渐变起点颜色
            fixed4 _Color2; // 渐变终点颜色
            float _Cutoff; // 透明度裁切
            float _ColorControl; // 颜色混合控制
            float _ColorRange; // 渐变范围

            fixed4 _SpecularColor; // 高光颜色
            float _Gloss; // 光泽强度
            float _Specular; // 最大高光指数
            float _SpecularMin; // 最小高光指数

            float _WindSpeed; // 风速
            float3 _OffsetAtten; // 风偏移强度

            float4 _PlayerPostition; // 玩家位置
            float _InteractionDistance; // 踩踏交互距离
            float _TreadStrength; // 踩踏强度

             // 重映射函数，用于数值范围变换
            float Remap(float value, float oldMin, float oldMax, float newMin, float newMax)
            {
                return newMin + (value - oldMin) * (newMax - newMin) / (oldMax - oldMin);
            }
            v2f vert (a2v v)
            {
                v2f o;
                //位移
                float4 vertex = v.vertex;
                float3 worldPos = mul(UNITY_MATRIX_M,vertex).xyz;
                //角色移动
                float _distance = clamp(distance(worldPos,_PlayerPostition.xyz),0,_InteractionDistance);
                _distance = Remap(_distance,0,_InteractionDistance,1,0);
                //风移动
                float3 sinPos = sin((_Time.x+ (worldPos.x + worldPos.z)/30) * _WindSpeed) * _OffsetAtten * pow(v.uv.y,2);
                float3 treadDir = normalize(worldPos - _PlayerPostition.xyz) * _TreadStrength * _distance;
                
                worldPos+=sinPos + treadDir;
                vertex = mul(unity_WorldToObject,float4(worldPos,1.0));

                
                //常规
                o.pos = UnityObjectToClipPos(vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(UNITY_MATRIX_M,vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //裁切
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(col.a - _Cutoff);
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

                //光照
                float3 worldNormal = normalize(i.normal);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 lightDir = normalize(_WorldSpaceLightPos0).xyz;

                float smoothness = tex2D(_SmoothnessTex,i.uv).r; // 获取光滑度
                float n = lerp(_SpecularMin,_Specular,1- smoothness); // 光滑度映射至高光指数

                float halfDir = normalize(viewDir + lightDir);
                float NdotL = max(0,dot(worldNormal,lightDir));
                float NdotH = max(0,dot(worldNormal,halfDir));
                fixed3 lightColor = _LightColor0.rgb;

                //增大区分度
                float ColorLerp =saturate( saturate( pow((i.uv.y+0.3),_ColorRange))-0.5);
                fixed3 albedo = (col *lerp(_Color2,_Color1*_ColorControl,ColorLerp)).rgb;
                fixed3 diffuse = lightColor * albedo * (NdotL*0.5+0.5);
                fixed3 specular = lightColor * pow(NdotH,n) * _SpecularColor.rgb * _Gloss;

                return fixed4((diffuse+specular)*atten,1);
            }
            ENDCG
        }

       
    }
Fallback "Transparent/Cutout/VertexLit"
}
