Shader "Final/Water"
{
    Properties
    {
        [Header(Main)]
        _Tint("Tint",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}

        // 泡沫效果相关属性
        [Header(Foam)]
        _Foam("Foam Tex",2D) = "white"{}
        _FoamColor("FoamColor",Color) = (1,1,1,1)
        _FoamFactor("FoamFactor",Float) = 0
        _FoamDepth("FoamDepth",Range(0,10)) = 0
        _FoamDetail("FoamDetail",Range(1,20)) = 1
        _FoamStrength("FoamStrength",Range(0.1,10)) = 1

        // 焦散效果相关属性
        [Header(Causitic)]
        _CausticTex("CausticTex",2D) = "white"{}
        _CausticSize("CausticSize",Float) = 1
        _CausticSpeed("CausticSpeed",Float) = 1
        _CausticColor("CausticColor",Color) = (1,1,1,1)
        _CausticDepth("CausticDepth",Range(0,1)) = 0
        _CausticStrength("CausticStrength",Range(0.1,10)) = 1



        // 法线贴图相关属性
        [Header(Normal)]
        _NormalTex("Normal Map",2D) = "bump"{}
        _NormalSize("Normal Size",Float) = 1
        _NormalRefract("NormalRefract",Range(0,10)) = 1

        // 高光效果相关属性
        [Header(Specular)]
        _Specular("Specular",Range(0.1,100)) = 1
        _Gloss("Gloss",Range(0.001,100)) = 1
        _SpecularColor("Specular Color",Color) = (1,1,1,1)

        // 深度相关属性
        [Header(Depth)]
        _DepthAtten("DepthAtten",Float) = 1 //高度差的放缩
        _WaveParams("WaveParams",Vector) = (1,1,1,1)
        _FresnelAtten("FresnelAtten",Range(0,2)) = 0.2

        // 反射效果相关属性
        [Header(Reflect)]
        _ReflectionTex("ReflectionTex",2D) = "white"{}
        _ReflectionFactor("ReflectionFactor",Float) = 1
        _Opacity("Opacity" , Range(0,10)) = 1
        _ReflectDistort("ReflectDistort",Range(0,0.1)) = 0.03

        // 颜色属性
        [Header(Color)]
        _WaterColorLight("WaterColorLight",Color) = (1,1,1,1)
        _WaterColorDark("WaterColorDark",Color) = (1,1,1,1)
        
        //折射
        _RefrDistortion("RefrDistortion",Range(0,100)) = 10  //折射强度
        
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
        }
        Blend SrcAlpha OneMinusSrcAlpha
            GrabPass {"_RefractionTex"} // 抓取屏幕纹理
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD4;
                float3 worldNormal : TEXCOORD1;
                float3 worldTangent : TEXCOORD2;
                float3 worldBinormal : TEXCOORD3;
                float4 screenPos:TEXCOORD5;
                float3 worldSpaceViewDir : TEXCOORD6;
                float viewSpaceZ : TEXCOORD7; //深度
            };
            
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float _NormalSize;
             fixed4 _Tint;
    
            //泡沫
            sampler2D _Foam;
            float4 _Foam_ST;
            fixed4 _FoamColor;
            float _FoamFactor;
            float _FoamDetail;
            float _FoamDepth;
            float _FoamStrength;
            

            //焦散相关
            sampler2D _CausticTex;
            float4 _CausticTex_ST;
            float _CausticSpeed;
            float _CausticSize;
            fixed4 _CausticColor;
            float _CausticDepth;
            float _CausticStrength;

            //高光
            fixed4 _SpecularColor;
            float _Gloss;
            float _Specular;
            
         
            
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;
            float _DepthAtten; //深度差缩放

            //深浅颜色
            fixed4 _WaterColorLight;
            fixed4 _WaterColorDark;

            //波动参数
            float4 _WaveParams;
            //菲涅尔衰减
            float _FresnelAtten;

            //反射
            sampler2D _ReflectionTex;
            float _ReflectionFactor;
            float _ReflectDistort;

            //不透明度
            float _Opacity;

            //折射
            sampler2D _RefractionTex;
            float _RefrDistortion;
            float4 _RefractionTex_TexelSize;
            float _NormalRefract;
           
            v2f vert(a2v v)
            {
                v2f o;
                // 将顶点坐标变换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算世界空间顶点位置
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;
                // 计算世界空间法线
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                // 计算世界空间切线
                o.worldTangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                // 计算世界空间副切线
                o.worldBinormal = normalize(cross(o.worldNormal, o.worldTangent) * v.tangent.w);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //screenPos除以w后，才是[0,1]的范围
                o.screenPos = ComputeScreenPos(o.pos);
                //世界空间的视线方向
                o.worldSpaceViewDir = WorldSpaceViewDir(v.vertex);
                //相机空间中该顶点的z值
                o.viewSpaceZ = mul(UNITY_MATRIX_V, float4(o.worldSpaceViewDir, 0.0)).z;
                // 非线性变化转为线性变化
                COMPUTE_EYEDEPTH(o.screenPos.z);

                return o;
            }


            //高度贴图转法线，与波浪相关
            float3 HeightToNormal(sampler2D HeightTex,float2 uv,float offset)
            {
                fixed r1 = tex2D(HeightTex,uv+float2(0.01,0)).r;
                fixed r2 = tex2D(HeightTex,uv+float2(-0.01,0)).r;
                fixed r3 = tex2D(HeightTex,uv+float2(0,0.01)).r;
                fixed r4 = tex2D(HeightTex,uv+float2(0,-0.01)).r;

                return normalize(cross(float3(offset,0,r1-r2),float3(0,offset,r3-r4)));
            }

            // 菲涅尔 Fresnel-Schlick
            inline float3 Unity_Fresnel(float3 F0, float cosA)
            {
                float a = pow((1 - cosA), 5);
                return (F0 + (1 - F0) * a);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 采样纹理获得深度值
                float depthScene = UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(i.screenPos)).r);
                //转化为线性,真实的物理距离  Linear01Depth是物理距离除以far的归一化距离
                depthScene = LinearEyeDepth(depthScene);
                //depthScene和ViewSpaceZ都是负数，这里是使用了相似三角形的性质。
                i.worldSpaceViewDir *= -depthScene / i.viewSpaceZ;
                //现在的worldSpaceViewDir是相机指向物体的向量

                //得到原来该深度的物体的时间空间位置
                float3 worldPosScene = _WorldSpaceCameraPos + i.worldSpaceViewDir;
                //得到世界空间里，水面和底面的高度差,真实的物理高度差
                float depthZ = saturate((i.worldPos - worldPosScene).y / _DepthAtten);


                // 根据深度差计算颜色    
                fixed4 waterColor = lerp(_WaterColorLight, _WaterColorDark, depthZ);

                //TBN矩阵与法线  
                float3 normalDir = normalize(i.worldNormal);
                float3 tangentDir = normalize(i.worldTangent);
                float3 binormalDir = normalize(i.worldBinormal);
                float3x3 TBN = float3x3(tangentDir, binormalDir, normalDir);

                // 使用法线纹理调整法线方向
                float2 waterUV = float2(i.worldPos.x, i.worldPos.z) * 0.1;
                fixed3 tangentNormal = normalize(
                    UnpackNormal(tex2D(_NormalTex, waterUV + _SinTime.x * _WaveParams.xy)) +
                    UnpackNormal(tex2D(_NormalTex, waterUV + (1 - _SinTime.x + _Time.x) * _WaveParams.zw)));

                //法线放缩
                tangentNormal.xy *= _NormalSize;
                tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                tangentNormal+= HeightToNormal(_MainTex,i.uv,0.01);
                // 将法线转化到世界空间
                float3 worldNormal = normalize(mul(tangentNormal, TBN));
                

                // 计算光照方向和视线方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);
                // 计算镜面反射和漫反射分量
                float NdotH = max(0, dot(halfDir, worldNormal));
                float NdotL = max(0, dot(worldNormal, lightDir));

                // 反射方向和屏幕UV调整   
                float2 trueScreenUV = i.screenPos.xy / i.screenPos.w;
                trueScreenUV.x = 1 - trueScreenUV.x;
                trueScreenUV.x += worldNormal.x * _ReflectDistort * depthZ;
                fixed3 reflecColor = tex2D(_ReflectionTex, trueScreenUV);

                // 根据深度差线性插值颜色
                fixed3 albedo = lerp(_WaterColorLight, _WaterColorDark, depthZ);
                fixed3 diffuse = _LightColor0.rgb * _Tint * albedo * saturate(NdotL * 0.5 + 0.5);
                fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(NdotH, _Specular * 128) * _Gloss;
                fixed3 ambient = _Tint * UNITY_LIGHTMODEL_AMBIENT.xyz;
                

                // 处理泡沫效果
                float2 foamUV = i.uv * _Foam_ST.xy + _Foam_ST.zw;
                fixed3 foam1 = tex2D(_Foam, foamUV * _FoamDetail + worldNormal.xy * 0.03 + _Time.x * _WaveParams.xy);
                fixed3 foam2 = tex2D(_Foam, foamUV * _FoamDetail + worldNormal.xy * 0.03 + (1 - _Time.x + _Time.x) * _WaveParams.zw);
                float depthMask = 1 - depthZ;
                float temp_output = saturate(saturate((foam1.g + foam2.g)) * depthMask - _FoamFactor);
                temp_output = smoothstep(0.08, 0.6, temp_output * _FoamDepth);


                diffuse = lerp(diffuse, _FoamColor * _FoamStrength, temp_output);
                

                // 计算菲涅耳效应
                float F0 = 0.02;
                float F = saturate(Unity_Fresnel(F0, dot(viewDir, i.worldNormal)) * _FresnelAtten);
                fixed3 color = lerp(diffuse + specular + ambient, reflecColor, F);

                //折射
                float2 offset = worldNormal.xz*_RefrDistortion * _RefractionTex_TexelSize.xy;
                float2 offsetPos = offset + i.screenPos.xy/i.screenPos.w;
                fixed3 refrCol = tex2D(_RefractionTex,offsetPos).rgb;
                 

                // 焦散
                float2 causticUV = worldPosScene.xz * _CausticTex_ST.xy * (1 - _CausticSize) * 10 + _CausticTex_ST.zw;
                float4 causticColor = tex2D(_CausticTex,float2(-causticUV.y + _CausticSpeed * 0.1 * sin(_Time.y),
                                            causticUV.x + _Time.x * _CausticSpeed * worldNormal.x * 0.01)) *_CausticColor *_CausticStrength;
                
                // 加上浅水域焦散效果
                color = lerp(color + causticColor, color, saturate(depthZ + _CausticDepth));
                return fixed4(color  , saturate(depthZ * _Opacity));
                return fixed4(refrCol*F*3 + color  , saturate(depthZ * _Opacity));
            }
            ENDCG
        }
    }
Fallback "Transparent/VertexLit"
}