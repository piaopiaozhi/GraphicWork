Shader "Unlit/IBL"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
        _CubeMap("Cube Map",Cube) = "white"{}
        _Tint("Tint",Color) = (1,1,1,1)
        _Expose("Expose",Float) = 1.0
        _Rotate("Rotate",Range(0,360)) = 0
        _NormalMap("Normal Map",2D) = "bump"{}
        _NormalIntensity("Normal Intensity",Float) = 1.0
        _AOMap("AO Map",2D) = "white"{}
        _AOAdjust("AO Adjust",Range(0,1)) = 1
        _RoughnessMap("Roughness Map",2D) = "black"{}
        _RoughnessContrast("Roughness Contrast",Range(0.01,10)) = 1
        _RoughnessBrightness("Roughness Brightness",Float)  = 1
        _RoughnessMin("Rough Min",Range(0,1)) = 0
        _RoughnessMax("Rough Max",Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal_world :TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                float3 tangent_world :TEXCOORD3;
                float3 binormal_world :TEXCOORD4;
            };

            sampler2D _MainTex;
            samplerCUBE _CubeMap;
            half4 _CubeMap_HDR;
            fixed4 _Tint;
            float _Expose;
            float _Rotate;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _NormalIntensity;
            sampler2D _AOMap;
            float _AOAdjust;
            sampler2D _RoughnessMap;
            float _RoughnessContrast;
            float _RoughnessBrightness;
            float _RoughnessMin;
            float _RoughnessMax;


            v2f vert (a2v v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * _NormalMap_ST.xy + _NormalMap_ST.zw;
                o.pos_world = mul(UNITY_MATRIX_M,v.vertex).xyz;
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.tangent_world = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);
                o.binormal_world = normalize(cross(o.normal_world,o.tangent_world)) * v.tangent.w;
                return o;
            }

            float3 RotateAround(float degree,float3 target)
            {
                float rad = degree * UNITY_PI/180;
                float2x2 m_rotate = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
                float2 dir_rotate = mul(m_rotate,target.xz);
                target = float3(dir_rotate.x,target.y,dir_rotate.y);
                return target;
            
            }

            inline float3 ACES_Tonemapping(float3 x)
            {
                float a = 2.51f;
                float b = 0.03f;
                float c = 2.43f;
                float d = 0.59f;
                float e = 0.14f;
                float3 encode_color = saturate((x*(a*x+b))/(x*(c*x+d)+e));
                return encode_color;
                
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 basecolor = tex2D(_MainTex,i.uv);
                half3 normal_dir = normalize(i.normal_world);
                half3 normaldata = UnpackNormal(tex2D(_NormalMap,i.uv));
                normaldata.xy = normaldata.xy * _NormalIntensity;
                half3 tangent_dir = normalize(i.tangent_world);
                half3 binormal_dir = normalize(i.binormal_world);
                normal_dir = normalize(tangent_dir * normaldata.x + binormal_dir * normaldata.y + normal_dir * normaldata.z);//TBN矩阵，切线空间下的法线方向转到了世界空间下的法线方向

                half ao = tex2D(_AOMap,i.uv).r;
                ao = lerp(1,ao,_AOAdjust);
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 reflect_dir = reflect(-view_dir,normal_dir);

                reflect_dir = RotateAround(_Rotate,reflect_dir);

                float roughness = tex2D(_RoughnessMap,i.uv);
                roughness = saturate(pow(roughness,_RoughnessContrast)*_RoughnessBrightness);
                roughness = lerp(_RoughnessMin,_RoughnessMax,roughness);
                roughness = roughness * (1.7-0.7*roughness);
                float mip_level = roughness*6.0;

                float4 uv_ibl = float4(normal_dir,mip_level);

                half4 color_cubemap = texCUBElod(_CubeMap,uv_ibl);
                //half3 env_color = DecodeHDR(color_cubemap,_CubeMap_HDR);
                half3 env_color = ShadeSH9(float4(normal_dir,1.0));
                half3 final_color =color_cubemap * ao * _Tint.rgb * _Tint.rgb * _Expose;
                half3 final_color_linear = pow(final_color,2.2);
                final_color = ACES_Tonemapping(final_color_linear);
                half3 final_color_gamma = pow(final_color,1.0/2.2);

                return float4(final_color_linear,1.0);
                
            }
            ENDCG
        }
    }
}
