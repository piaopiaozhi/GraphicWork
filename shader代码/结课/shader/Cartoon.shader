Shader "Unlit/Cartoon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap("Normal",2D) = "bump"{}
        _AOMap("AOMap",2D) = "white"{}
        _StrokeWeight("_StrokeWeight",Range(0.01,1)) = 0.01
        _StrokeColor("StrokeColor",Color) = (0,0,0,0)
        _ShadowRange("ShadowRange",Range(0,1)) = 0.5
        _ShadowColor("ShadowColor",Color) = (1,1,1,1)
        _WarmColor("WarmColor",Color) = (1,1,1,1)
        _ShadowSmooth("ShadowSmooth",Float) = 1
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        _SpecularGloss("SpecularGloss",Range(1,100)) = 30

        _Alpha("Translation Alpha", Range(-1, 1)) = 0.5
        _Beta("Translation Beta", Range(-1, 1)) = 0.5
        _Sigma1("Scaling Sigma", Range(0, 1)) = 0.5
        _Gamma1("Split Gamma 1", Range(0, 1)) = 0.5
        _Gamma2("Split Gamma 2", Range(0, 1)) = 0.5
        _N("SquareN",Range(0,10)) = 1
         _Sigma2("Scaling Sigma", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        //正常Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 tangent : TEXCOORD3;
                float3 binormal : TEXCOORD4;
                float3 pos_world : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            sampler2D _AOMap;
            float _ShadowRange;
            fixed4 _WarmColor;
            fixed4 _ShadowColor;
            float _ShadowSmooth;
            fixed4 _SpecularColor;
            float _SpecularGloss;

            float _Alpha;
            float _Beta;
            float _Sigma1;
            float _Gamma1;
            float _Gamma2;
            float _N;
            float _Sigma2;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.normal_world = normalize(UnityObjectToWorldNormal(v.normal));
                o.tangent =normalize( mul((float3x3)UNITY_MATRIX_M,v.tangent.xyz));
                o.binormal =normalize( cross(o.normal_world ,o.tangent) * v.tangent.w);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal_world = normalize(i.normal_world);
                float3 tangentnormal = UnpackNormal(tex2D(_NormalMap,i.uv));
                float3x3 tangentToWorld = float3x3(i.tangent,i.binormal,i.normal_world);
                float3 normal_world =normalize( mul(tangentToWorld,tangentnormal));

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                float3 LightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 lightColor = _LightColor0.rgb;

                float darkness  = ((dot(normal_world,LightDir))*0.5+0.5);
                half ramp = smoothstep(0, _ShadowSmooth, darkness - _ShadowRange);

                //half3 diffuse = lerp(_ShadowColor, _WarmColor, ramp);
                 half3 diffuse = darkness>_ShadowRange?_WarmColor:_ShadowColor;
                fixed4 Maincol = tex2D(_MainTex, i.uv);
                fixed4 lambertColor = fixed4(diffuse,1.0) * Maincol * fixed4(lightColor,1.0);

                float3 halfDir = normalize((LightDir + viewDir));

                //高光形状操作

                 // 平移
                halfDir = normalize(halfDir + _Alpha * i.tangent + _Beta * i.binormal);

                // 缩放
                halfDir = normalize(halfDir - _Sigma1 * dot(halfDir, i.tangent) * i.tangent);

                // 分割
                halfDir = normalize(halfDir - _Gamma1 * sign(dot(halfDir, i.tangent)) * i.tangent 
                                   - _Gamma2 * sign(dot(halfDir, i.binormal)) * i.binormal);

                // 方块化
                float theta = min(acos(dot(halfDir, i.tangent)), acos(dot(halfDir, i.binormal)));
                float sqrnorm = pow(sin(2 * theta), _N);

                halfDir = normalize(halfDir - _Sigma2 * sqrnorm * (dot(halfDir, i.tangent) * i.tangent 
                                                               + dot(halfDir, i.binormal) * i.binormal));



                fixed4 specular = pow(saturate(dot(halfDir,normal_world)),_SpecularGloss) * _SpecularColor;

               
                return lambertColor + specular;
            }
            ENDCG
        }

        //轮廓Pass
        Pass
        {
            Cull Front
             CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _StrokeWeight;
            fixed4 _StrokeColor;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                fixed4 vertcolor : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed4 vertColor : TEXCOORD1;
            };

            

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float3 norm =normalize( mul((float3x3)UNITY_MATRIX_IT_MV,v.normal));
                float2 expend_dir = normalize(TransformViewToProjection(norm.xy));

                //近处，描边宽度不变的位置
                float aspect = _ScreenParams.x/_ScreenParams.y;
                expend_dir.x /= aspect; //屏幕宽高比
                o.pos.xy += expend_dir* o.pos.w *_StrokeWeight*0.1;

                //计算在远处，近大远小的顶点位置
                float3 worldNormal =normalize( UnityObjectToWorldNormal(v.normal));
                float3 worldPos = mul(UNITY_MATRIX_M,v.vertex).xyz;
                worldPos += worldNormal*_StrokeWeight*0.1;
                float4 farPos = UnityWorldToClipPos(worldPos);

                //插值
                float dist = distance(unity_ObjectToWorld._m03_m13_m23, _WorldSpaceCameraPos);
                o.pos = lerp(o.pos,farPos,saturate(dist * 0.2));

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertColor = v.vertcolor;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = _StrokeColor * i.vertColor;
                return col;
            }
            ENDCG
        }
    }
}
