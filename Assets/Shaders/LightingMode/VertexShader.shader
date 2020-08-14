Shader "Wdx/ShaderBook/VertexShader"
{
    Properties
    {
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment  frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;

            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                v2f f;

                f.pos = UnityObjectToClipPos(v.vertex);

                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal=normalize(UnityObjectToWorldNormal(v.normal));

                fixed3 lightDir=normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,lightDir));

                f.color=ambient+diffuse;

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                return fixed4(f.color , 1);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"
}