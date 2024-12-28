Shader "Unlit/Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseMap("Noise Map",2D) = "white"{}
        _DissolveValue("Dissolve Value",Range(0,1.001)) =0
        _DissolveSize("Dissolve Size",Range(0,1.001)) = 0
        _DissolveColor("Dissolve Color",Color) = (1,1,1,1)
        _DissolveAddColor("Dissolve Add Color",Color) = (1,1,1,1)
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
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;
            float _DissolveValue;
            float _DissolveSize;
            fixed4 _DissolveColor;
            fixed4 _DissolveAddColor;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseMap);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv.xy);

                float dissolve = tex2D(_NoiseMap,i.uv.zw).g;
                float clipValue = dissolve - _DissolveValue;
                clip(clipValue);

                if(dissolve > 0 && clipValue<_DissolveSize)
                {

                    fixed4 color  = lerp(_DissolveColor,_DissolveAddColor,(clipValue/_DissolveSize)*2);
                    col *= color;
                }

                return col;
            }
            ENDCG
        }
    }
}
