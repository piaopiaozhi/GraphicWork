Shader "Unlit/RippleShader"
{
    Properties
    {

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _PrevRT;
            sampler2D _CurrentRT;
            float4 _CurrentRT_TexelSize;

            float _RippleDecrese;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 e = float3(_CurrentRT_TexelSize.xy,0);
                float2 uv = i.uv;
                //获取上下左右值
                float p10 = tex2D(_CurrentRT,uv-e.zy).x;//下
                float p01 = tex2D(_CurrentRT,uv-e.xz).x;//左
                float p21 = tex2D(_CurrentRT,uv+e.xz).x;//右
                float p12 = tex2D(_CurrentRT,uv+e.zy).x;//上

                float p11 = tex2D(_PrevRT,uv).x;
                //减去p11是为了防止往回跑
                float d =(p10 + p01 + p21 +p12)/2 - p11;
                d*= _RippleDecrese;
                return d;
            }
            ENDCG
        }
    }
}
