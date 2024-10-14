Shader "Hidden/DepthOfField"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {

        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        sampler2D _BlurTex;
        sampler2D _CameraDepthTexture;
        half4 _MainTex_TexelSize;
        fixed _FocusDistance;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
            float4 vertex : SV_POSITION;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);

            o.uv.xy = v.uv;
            o.uv.zw = v.uv;
            o.uv_depth = v.uv;

            #if UNITY_UV_STARTS_AT_TOP
             if(_MainTex_TexelSize.y<0){
                 o.uv.w=1.0-o.uv.w;
                 o.uv_depth.y=1.0-o.uv_depth.y;
             }
             #endif

            return o;
        }


        fixed4 frag (v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex,i.uv.xy);
            fixed4 bcol = tex2D(_BlurTex,i.uv.zw);

            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
            depth = Linear01Depth(depth);

            fixed bVa = abs(depth - _FocusDistance);
            return lerp(col,bcol,bVa);
            
        }
        ENDCG

        ZTest Always
        Cull Off
        ZWrite Off

        UsePass "MyUnlit/GaussianBlur/GAUSSIANBLUR_V"
        UsePass "MyUnlit/GaussianBlur/GAUSSIANBLUR_H"

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
        Fallback Off
    
}
