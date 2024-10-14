Shader "Hidden/FrostedGlass"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
         _BlurAmount ("Blur Amount",Float) = 1.0
        _Transparency ("Transparency", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderType" = "Transparent" "Queue" = "Transparent"}
        LOD 100

         GrabPass { "_GrabTexture" } // 抓取当前屏幕内容

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

          
           struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 grabPos : TEXCOORD1;
            };

            sampler2D _MainTex; 
            float4 _MainTex_TexelSize;
            sampler2D _GrabTexture; 
            float _BlurAmount; 
            float _Transparency; 

             v2f vert (appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.grabPos = ComputeGrabScreenPos(o.pos); // 计算屏幕位置
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 uv = i.grabPos.xy / i.grabPos.w; 

                float2 uvoffsets = _MainTex_TexelSize.xy;
                half4 color = tex2D(_GrabTexture, uv) * 0.25; // 中心
                color += tex2D(_GrabTexture, uv + uvoffsets * float2(-_BlurAmount, -_BlurAmount)) * 0.0625; // 左上
                color += tex2D(_GrabTexture, uv + uvoffsets * float2( 0, -_BlurAmount)) * 0.125;          // 上
                color += tex2D(_GrabTexture, uv + uvoffsets * float2(_BlurAmount, -_BlurAmount)) * 0.0625;  // 右上

                color += tex2D(_GrabTexture, uv + uvoffsets * float2(-_BlurAmount, 0)) * 0.125;           // 左
                color += tex2D(_GrabTexture, uv + uvoffsets * float2(_BlurAmount, 0)) * 0.125;            // 右

                color += tex2D(_GrabTexture, uv + uvoffsets * float2(-_BlurAmount, _BlurAmount)) *0.0625;  // 左下
                color += tex2D(_GrabTexture, uv + uvoffsets * float2( 0, _BlurAmount)) * 0.125;            // 下
                color += tex2D(_GrabTexture, uv + uvoffsets * float2(_BlurAmount, _BlurAmount)) * 0.0625;   // 右下


                half4 glassColor = tex2D(_MainTex, i.uv);
                color = lerp(glassColor, color, _Transparency); 

                return color;
            }
            ENDCG
        }
       
    }

   
}
