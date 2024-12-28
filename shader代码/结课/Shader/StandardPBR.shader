Shader "FinalClass/StandardPBR"
{
    Properties
    {
        //染色
        _Tint("Color",Color) = (1,1,1,1)
        //Albedo贴图
        _MainTex ("Texture", 2D) = "white" {}
        //法线贴图
        _Normal("Normal Map",2D) = "white"{}
        //法线凹凸
        _NormalSize("Normal Size",Float) = 1
        //金属度贴图
        _MetallicSmoothness("Metallic Map",2D) = "white"{}
        //金属度
        [Gamma] _Metallic("Metallic", Range(0, 1)) = 0 //金属度要经过伽马校正
        //1-粗糙度
         _Smoothness("Smoothness", Range(0.001, 1)) = 0.5
        //粗糙度混合，使用Albedo还是数值
        [Header(0 map 1 albedo)]
        _SmoothnessBlend("Smoothness Blend", Range(0, 1)) = 0
        //自发光贴图
        _EmissionMap("Emission Map",2D) = "black"{}
        //LUT纹理，用于BRDF采样
        _LUT("LUT", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        Cull Off
        LOD 100

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include  "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION; //顶点坐标
                float2 uv : TEXCOORD0; //uv坐标
                float3 normal : NORMAL; //法线
                float4 tangent : TANGENT; //切线
            };

            struct v2f
            {
                float2 uv : TEXCOORD0; 
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD1; //世界空间坐标
                float3 worldNormal : TEXCOORD2; //世界空间法线
                float3 worldTangent : TEXCOORD3; //世界空间切线
                float3 worldBinormal : TEXCOORD4; //世界空间副切线

                SHADOW_COORDS(5) 
            };

            //变量
            half4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Normal;
            float _NormalSize;
            sampler2D _MetallicSmoothness;
            float _Metallic;
			float _Smoothness;
            float _SmoothnessBlend;
            sampler2D _LUT;
            sampler2D _EmissionMap;

            v2f vert (a2v v)
            {
                v2f o;
                // 将顶点坐标变换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                 // 计算世界空间顶点位置
                o.worldPos = mul(UNITY_MATRIX_M,v.vertex).xyz;
                 // 计算世界空间法线
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                 // 计算世界空间切线
                o.worldTangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                // 计算世界空间副切线
                o.worldBinormal = normalize(cross(o.worldNormal,o.worldTangent)*v.tangent.w);
                // 传递 UV 坐标
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 传递阴影坐标
                TRANSFER_SHADOW(o);
                return o;
            }

            
            // 菲涅尔公式（带粗糙度调整）
            float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
            {
	            return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //TBN矩阵与法线
                float3 normalDir = normalize(i.worldNormal);
                float3 tangentDir = normalize(i.worldTangent);
                float3 binormalDir = normalize(i.worldBinormal);
                float3x3 TBN = float3x3(tangentDir,binormalDir,normalDir);
                // 法线贴图处理（切线空间转世界空间）
                float3 normalTex = UnpackNormal(tex2D(_Normal,i.uv));
                normalTex.xy *= _NormalSize;
                normalTex.z = sqrt(1.0 - saturate(dot(normalTex.xy,normalTex.xy)));
                float3 worldNormal = normalize(mul(normalTex,TBN));
                
                //光方向，视线方向，半角向量            
                float3 lightDir = normalize(_WorldSpaceLightPos0);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 halfDir = normalize(lightDir + viewDir);

                //光颜色
                float3 lightColor = _LightColor0.rgb;

                //基础色
                float3 albedo = _Tint * tex2D(_MainTex, i.uv);
                float smoothnessByalbedo = tex2D(_MainTex,i.uv).a;
                float smoothFromMettalic = tex2D(_MetallicSmoothness,i.uv).a;
                _Smoothness *= lerp(smoothFromMettalic,smoothnessByalbedo,_SmoothnessBlend);
                
                //粗糙度家族
                float perceptualRoughness = 1 - _Smoothness;//粗糙度
                float roughness = perceptualRoughness * perceptualRoughness;//粗糙度平方
	            float squareRoughness = roughness * roughness;//粗糙度四次方

                //为brdf准备
                float nl = max(saturate(dot(worldNormal, lightDir)), 0.000001);//光线与法线夹角 防止除0
	            float nv = max(saturate(dot(worldNormal, viewDir)), 0.000001);//视线与法线
	            float vh = max(saturate(dot(viewDir, halfDir)), 0.000001);//视线与半角向量
	            float lh = max(saturate(dot(lightDir, halfDir)), 0.000001); //光线与半角向量
	            float nh = max(saturate(dot(worldNormal, halfDir)), 0.000001); //法线与半角向量

                
                
                
                // === 直接光照计算 ===
                //法线分布函数
                float lerpSquareRoughness = pow(lerp(0.002, 1, roughness), 2);//Unity把roughness lerp到了0.002
                float D = lerpSquareRoughness / (pow((pow(nh, 2) * (lerpSquareRoughness - 1) + 1), 2) * UNITY_PI);

                //几何遮蔽函数
                float kInDirectLight = pow(squareRoughness + 1, 2) / 8;
                float kInIBL = pow(squareRoughness, 2) / 8;
                float GLeft = nl / lerp(nl, 1, kInDirectLight);
                float GRight = nv / lerp(nv, 1, kInDirectLight);
                float G = GLeft * GRight;

                //金属度
                float metallicTexValue = pow( tex2D(_MetallicSmoothness,i.uv).r,1.0f/2.2f); //读取贴图并转换到伽马空间

                //混合金属度
                _Metallic *= metallicTexValue;
                
                // 计算菲涅尔反射项 F0（在法线方向的反射率）
                // 对于非金属，使用固定的反射率（unity_ColorSpaceDielectricSpec.rgb，一般约为0.04）
                // 对于金属，使用物体自身的颜色（albedo）
                float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, _Metallic);
                // 计算菲涅尔项 F，使用近似的 Schlick 方程
                float3 F = F0 + (1 - F0) * exp2((-5.55473 * vh - 6.98316) * vh);

                // 计算 Cook-Torrance BRDF 的镜面反射项
                float3 SpecularResult = (D * G * F * 0.25) / (nv * nl);

                // 计算漫反射系数 kd，确保能量守恒
                // 对于金属（_Metallic 接近 1），kd 应为 0（金属不反射漫反射光）
                float3 kd = (1 - F)*(1 - _Metallic);
                
                //直接光 高光项
                float3 specColor = SpecularResult * lightColor * nl * UNITY_PI;
                //直接光 漫反射项
                float3 diffColor = kd * albedo * lightColor * nl;

                fixed3 DirectLightResult = diffColor + specColor;
               
                // === 阴影衰减 ===
                // 从阴影宏中获取衰减
                half shadow = SHADOW_ATTENUATION(i);
                // 将阴影衰减乘到直射光结果
                DirectLightResult *= shadow;

                // === 间接光照计算 ===

                // 使用球谐函数计算环境漫反射贡献（间接光漫反射部分）
                half3 ambient_contrib = ShadeSH9(float4(worldNormal, 1));

                // 添加一个小的环境光，模拟全局的环境亮度
                float3 ambient = 0.03 * albedo;

                // 计算总的间接漫反射光照，确保结果非负
                float3 iblDiffuse = max(half3(0, 0, 0), ambient.rgb + ambient_contrib);
                
                // 计算用于采样环境贴图的粗糙度（考虑 MIP 贴图层级）
                float mip_roughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
                // 反射向量
                float3 reflectVec = reflect(-viewDir, worldNormal);

                // 根据粗糙度计算需要采样的 MIP 层级
                half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
                //采样间接镜面反射光照
                half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip); 

                //解码
                float3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
                
                // 从预计算的 LUT（查找表）中采样 BRDF 参数
				float2 envBDRF = tex2D(_LUT, float2(lerp(0, 0.99, nv), lerp(0, 0.99, roughness))).rg; // LUT采样

                // 计算考虑粗糙度的菲涅尔项，用于间接光照
				float3 Flast = fresnelSchlickRoughness(max(nv, 0.0), F0, roughness);
				float kdLast = (1 - Flast) * (1 - _Metallic);

                //间接光漫反射结果 与 间接光镜面反射结果
				float3 iblDiffuseResult = iblDiffuse * kdLast * albedo;
				float3 iblSpecularResult = iblSpecular * (Flast * envBDRF.r + envBDRF.g);
                
                //间接光总和
                float3 ibl = iblDiffuseResult + iblSpecularResult;

                //自发光
                float3 emission = tex2D(_EmissionMap,i.uv);
                 
                return float4(emission +  DirectLightResult + ibl, 1.0);
            }
            ENDCG
        }
        
    }
Fallback "Diffuse"
}
