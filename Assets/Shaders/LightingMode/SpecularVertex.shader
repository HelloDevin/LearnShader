Shader "Wdx/ShaderBook/SpecularVertex"
{
    Properties
    {
        _Diffuse ("Diffuse Color", Color) = (1, 1, 1, 1)
        _Specular ("Specular Color ", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
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
            fixed4 _Specular;
            float _Gloss;

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

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

                fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * (dot(worldNormal, lightDir)*0.5+0.5);

                fixed3 reflectDir=normalize(reflect(-lightDir,worldNormal));

                fixed3 viewDir =normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex).xyz);
                
                fixed3 specular  =_LightColor0.rgb*_Specular.rgb*pow(saturate(dot(reflectDir,viewDir)),_Gloss);

                f.color = ambient + diffuse+specular;

                return f;
            }

            fixed4 frag(v2f f) : SV_Target
            {

                return fixed4(f.color, 1);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}