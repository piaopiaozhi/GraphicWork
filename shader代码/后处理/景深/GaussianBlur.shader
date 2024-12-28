Shader "MyUnlit/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

            CGINCLUDE

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                half2 uv[5] : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _BlurSize;

            v2f vert_v (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = v.uv;
                o.uv[0] = uv;
                o.uv[1] = uv + float2(0.0,_MainTex_TexelSize.y * 1.0)*_BlurSize;
                o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y*1.0)*_BlurSize;
                o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y*2.0)*_BlurSize;
                o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y*2.0)*_BlurSize;


                return o;
            }

             //���ڼ������ģ������������Ԫ��
          v2f vert_h(appdata v)
          {
              v2f o;
              o.pos = UnityObjectToClipPos(v.vertex);
              half2 uv = v.uv;
 
              //������ͬ��ֻ������x�����ģ��ƫ��
              o.uv[0] = uv;
              o.uv[1] = uv + float2( _MainTex_TexelSize.x*1.0,0.0)*_BlurSize;
              o.uv[2] = uv - float2( _MainTex_TexelSize.x*1.0,0.0)*_BlurSize;
              o.uv[3] = uv + float2( _MainTex_TexelSize.x*2.0,0.0)*_BlurSize;
              o.uv[4] = uv - float2( _MainTex_TexelSize.x*2.0,0.0)*_BlurSize;

              return o;
          }

            fixed4 frag (v2f i) : SV_Target
            {
               float weights[3] = {0.4026,0.2442,0.0545};
 
              fixed4 col = tex2D(_MainTex, i.uv[0]);
  
              fixed3 sum = col.rgb*weights[0];
 
             //�Բ���������ж�Ӧ����ƫ�������Ȩ�ؼ��㣬�Եõ�ģ����Ч��
               for (int it = 1; it < 3; it++) 
              {
                  sum += tex2D(_MainTex, i.uv[2 * it - 1]).rgb*weights[it];//��Ӧ1��3��Ҳ����ԭʼ���ص��Ϸ�������
                  sum += tex2D(_MainTex, i.uv[2 * it]).rgb*weights[it];//��Ӧ2��4���·�������
              }
              fixed4 color = fixed4(sum, 1.0);
              return color;
            }
            ENDCG

            ZTest Always
            Cull Off
            ZWrite Off

            Pass
            {
                NAME "GAUSSIANBLUR_V"
                CGPROGRAM
                #pragma vertex vert_v
                #pragma fragment frag

                ENDCG
            }

            Pass
            {
                NAME "GAUSSIANBLUR_H"
                CGPROGRAM
                #pragma vertex vert_h
                #pragma fragment frag

                ENDCG
            }
        
    }
    Fallback Off
}
